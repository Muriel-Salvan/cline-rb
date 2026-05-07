require 'tmpdir'

describe Cline::Cli, '#interrupt' do
  let(:cli) { described_class.new }

  it 'kills the direct cline_pid process' do
    test_pid = nil
    mock_commands(
      'cline auth' => {
        exec: proc do |mocked_result|
          # Spawn a real process
          ClineTest::Helpers.original_popen3.call('ruby -e"sleep 60"') do |stdin, _stdout, _stderr, wait_thr|
            mocked_result[:pid] = wait_thr.pid
            test_pid = mocked_result[:pid]
            stdin.close
          end
        end,
        pid: proc do
          # We need the real external process PID
          sleep 0.1 until test_pid
          test_pid
        end
      }
    )
    allow(Process).to receive(:kill).and_call_original
    # Create another thread to interrupt the running command
    interruptor_thread = Thread.new do
      # Wait for the command execution to start
      sleep 0.1 until cli.cline_pid
      cli.interrupt
    end
    begin
      cli.auth
    ensure
      interruptor_thread.join
    end
    expect(Process).to have_received(:kill).with('KILL', test_pid)
  end

  it 'kills the cline_pid and all its child subprocesses recursively' do
    start_finished = false
    test_pids = []
    mock_commands(
      'cline auth' => {
        exec: proc do |mocked_result|
          # Spawn a tree of processes
          Dir.mktmpdir do |temp_dir|
            spawn_file = "#{temp_dir}/spawn.rb"
            File.write(
              spawn_file,
              <<~EO_RUBY
                $stdout.sync = true
                nbr_children = Integer(ARGV[0])
                puts "PID: \#{Process.pid}"
                if nbr_children > 0
                  system "ruby #{spawn_file} \#{nbr_children - 1}"
                else
                  puts 'Sleeping'
                  sleep 60
                end
              EO_RUBY
            )
            ClineTest::Helpers.original_popen3.call("ruby #{spawn_file} 4") do |stdin, stdout, _stderr, wait_thr|
              mocked_result[:pid] = wait_thr.pid
              stdin.close
              Thread.new do
                stdout.each_line do |line|
                  if line =~ /PID: (\d+)/
                    test_pids << Integer(Regexp.last_match(1))
                  elsif line == "Sleeping\n"
                    start_finished = true
                  end
                end
              end.join
            end
          end
        end,
        pid: proc do
          # We need the real external process PID
          sleep 0.1 until start_finished
          test_pids.first
        end
      }
    )
    allow(Process).to receive(:kill).and_call_original
    # Create another thread to interrupt the running command
    interruptor_thread = Thread.new do
      # Wait for the command execution to start
      sleep 0.1 until cli.cline_pid
      cli.interrupt
    end
    begin
      cli.auth
    ensure
      interruptor_thread.join
    end
    # Verify that the 5 child processes were found
    expect(test_pids.size).to eq 5
    test_pids.each do |test_pid|
      expect(Process).to have_received(:kill).with('KILL', test_pid)
    end
  end

  context 'when no cline_pid is present' do
    it 'does not attempt to kill any processes' do
      allow(Process).to receive(:kill).and_call_original
      cli.interrupt
      expect(Process).not_to have_received(:kill)
    end
  end

  context 'when processes disappear while enumerating' do
    it 'gracefully handles errors' do
      mock_commands('cline auth' => { pid: 9876, running_time_secs: 0.5 })
      # Simulate an error while fetching process children
      allow(Sys::ProcTable).to receive(:ps).and_raise(StandardError.new('Process table error'))
      allow(Process).to receive(:kill)
      # Create another thread to interrupt the running command
      Thread.new do
        # Wait a bit for command execution to start
        sleep 0.2
        expect { cli.interrupt }.not_to raise_error
      end
      cli.auth
      expect(Sys::ProcTable).to have_received(:ps)
      expect(Process).to have_received(:kill).with('KILL', 9876)
    end
  end
end
