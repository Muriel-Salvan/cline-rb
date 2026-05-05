shared_examples 'a cli command' do |opts|
  before do
    mock_commands
  end

  it 'calls the correct command' do
    described_class.new.public_send(opts[:name])
    expect(issued_commands).to eq ["cline #{opts[:name]}"]
  end

  it 'includes global constructor options in the command' do
    described_class.new(
      verbose: true,
      cwd: '/test/path',
      config: '/test/config.yml'
    ).public_send(opts[:name])
    expect(issued_commands).to eq ["cline #{opts[:name]} --verbose --cwd /test/path --config /test/config.yml"]
  end

  if opts[:options].any?
    it 'includes command options in the command' do
      described_class.new.public_send(opts[:name], **opts[:options])
      expect(issued_commands).to eq ["cline #{opts[:name]} #{opts[:cli_options]}"]
    end

    it 'combines global and command options correctly' do
      described_class.new(verbose: true, cwd: '/working/dir').public_send(opts[:name], **opts[:options])
      expect(issued_commands).to eq ["cline #{opts[:name]} --verbose --cwd /working/dir #{opts[:cli_options]}"]
    end
  end

  it 'raises UnknownOptionError for invalid command options' do
    cli = described_class.new
    expect do
      cli.public_send(opts[:name], invalid_option: 'value')
    end.to raise_error(Cline::Cli::UnknownOptionError, "Unknown #{opts[:name]} option invalid_option")
  end

  it 'returns stdout, stderr and exit_status correctly' do
    mock_commands(
      "cline #{opts[:name]}" => {
        stdout: "Executing Cline CLI\nSuccess\n",
        stderr: "Warning: update available\n"
      }
    )
    # Mute stderr
    allow($stderr).to receive(:write)
    result = described_class.new.public_send(opts[:name])
    expect(result).to eq(
      stdout: "Executing Cline CLI\nSuccess\n",
      stderr: "Warning: update available\n",
      exit_status: 0
    )
  end

  it 'raises UnexpectedExitStatusError when exit status is not expected' do
    mock_commands("cline #{opts[:name]}" => { exit_status: 1 })
    cli = described_class.new
    expect do
      cli.public_send(opts[:name])
    end.to raise_error(Cline::Cli::UnexpectedExitStatusError)
  end

  it 'has correct cline_pid value while running command' do
    mock_commands("cline #{opts[:name]}" => { pid: 9876, running_time_secs: 0.5 })
    cli = described_class.new
    # Create another thread to capture PID while the command is running
    captured_pid = nil
    pid_thread = Thread.new do
      # Wait a bit for command execution to start
      sleep 0.1
      captured_pid = cli.cline_pid
    end
    cli.public_send(opts[:name])
    pid_thread.join
    expect(captured_pid).to eq(9876)
  end

  it 'has nil cline_pid after running command' do
    cli = described_class.new
    cli.public_send(opts[:name])
    expect(cli.cline_pid).to be_nil
  end
end
