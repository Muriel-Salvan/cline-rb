describe Cline::Cli, '#interrupt' do
  let(:cli) { described_class.new }

  ClineTest::Helpers::Os.possible_oses.each do |host_os|
    context "when running on OS #{host_os}" do
      around do |example|
        with_host_os(host_os) do
          example.call
        end
      end

      it 'kills the direct cline_pid process' do
        mock_commands('cline auth' => { running_time_secs: 60 })
        spy_killing_pids
        # Create another thread to interrupt the running command
        cline_pid = nil
        interruptor_thread = Thread.new do
          # Wait for the command execution to start
          sleep 0.1 until cli.cline_pid
          cline_pid = cli.cline_pid
          cli.interrupt
        end
        begin
          cli.auth
        ensure
          interruptor_thread.join
        end
        expect(killed_pids).to include(cline_pid)
      end

      it 'kills the cline_pid and all its child subprocesses recursively' do
        # Create a Ruby script that will spawn a tree of processes
        with_temp_dir do |temp_dir|
          # Create a Ruby script that will spawn several sub-processes and log their PIDs in a log file
          spawn_file = "#{temp_dir}/spawn.rb"
          log_file = "#{temp_dir}/log.txt"
          File.write(
            spawn_file,
            <<~EO_RUBY
              nbr_children = Integer(ARGV[0])
              File.write('#{log_file}', "PID: \#{Process.pid}\n", mode: 'a+')
              if nbr_children > 0
                system "ruby #{spawn_file} \#{nbr_children - 1}", exception: true
              else
                File.write('#{log_file}', "Sleeping\n", mode: 'a+')
                puts 'Sleeping'
                sleep 60
              end
            EO_RUBY
          )
          # Monitor the log file to know when the processes have finished starting and get all their PIDs
          cline_pids = nil
          log_monitor_thread = Thread.new do
            loop do
              if File.exist?(log_file)
                log = File.read(log_file)
                if log.include?('Sleeping')
                  cline_pids = log.scan(/^PID: (\d+)$/).map { |match| Integer(match.first) }
                  break
                end
              end
              sleep 0.5
            end
          end
          begin
            mock_commands(
              'cline auth' => {
                eval: "system 'ruby #{spawn_file} 4 2>&1'"
              }
            )
            spy_killing_pids
            # Create another thread to interrupt the running command
            interruptor_thread = Thread.new do
              # Wait for the command execution to start
              sleep 0.1 until cli.cline_pid && cline_pids
              cline_pids << cli.cline_pid
              cli.interrupt
            end
            begin
              cli.auth
            ensure
              interruptor_thread.join
            end
            # Verify that all the child processes were found
            expect(cline_pids.size).to eq 6
            cline_pids.each do |cline_pid|
              expect(killed_pids).to include(cline_pid)
            end
          ensure
            log_monitor_thread.join
          end
        end
      end

      it 'does not attempt to kill any processes when no cline_pid is present' do
        spy_killing_pids
        cli.interrupt
        expect(killed_pids).to be_empty
      end

      it 'gracefully handles errors when processes disappear while enumerating' do
        mock_commands('cline auth' => { running_time_secs: 60 })
        # Simulate an error while fetching process children
        allow(Sys::ProcTable).to receive(:ps).and_raise(StandardError.new('Process table error'))
        spy_killing_pids
        # Create another thread to interrupt the running command
        cline_pid = nil
        interruptor_thread = Thread.new do
          # Wait a bit for command execution to start
          sleep 0.1 until cli.cline_pid
          cline_pid = cli.cline_pid
          expect { cli.interrupt }.not_to raise_error
        end
        begin
          cli.auth
        ensure
          interruptor_thread.join
        end
        expect(Sys::ProcTable).to have_received(:ps)
        expect(killed_pids).to include(cline_pid)
      end

      it 'gracefully handles errors when process disappears just before killing it' do
        mock_commands('cline auth' => { running_time_secs: 0.5 })
        cline_pid = nil
        spy_killing_pids(
          on_kill: proc do
            # Wait for the cline_pid to disappear
            sleep 0.1 while Sys::ProcTable.ps(pid: cline_pid)
          end
        )
        # Create another thread to interrupt the running command
        interruptor_thread = Thread.new do
          # Wait a bit for command execution to start
          sleep 0.1 until cli.cline_pid
          cline_pid = cli.cline_pid
          expect { cli.interrupt }.not_to raise_error
        end
        begin
          cli.auth
        ensure
          interruptor_thread.join
        end
        expect(killed_pids).to include(cline_pid)
      end
    end
  end
end
