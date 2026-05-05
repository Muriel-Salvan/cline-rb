describe Cline::Cli, '#auth' do
  before do
    mock_commands
  end

  it 'calls the correct command' do
    described_class.new.auth
    expect(issued_commands).to eq ['cline auth']
  end

  it 'includes global constructor options in the command' do
    described_class.new(
      verbose: true,
      cwd: '/test/path',
      config: '/test/config.yml'
    ).auth
    expect(issued_commands).to eq ['cline auth --verbose --cwd /test/path --config /test/config.yml']
  end

  it 'includes command options in the command' do
    described_class.new.auth(
      provider: 'openai-native',
      apikey: 'test-key-123',
      modelid: 'gpt-4o',
      baseurl: 'https://my-server.com/api'
    )
    expect(issued_commands).to eq [
      'cline auth --provider openai-native --apikey test-key-123 --modelid gpt-4o --baseurl https://my-server.com/api'
    ]
  end

  it 'combines global and command options correctly' do
    described_class.new(verbose: true, cwd: '/working/dir').auth(
      provider: 'anthropic',
      apikey: 'anthropic-key',
      modelid: 'claude-sonnet-4-6'
    )
    expect(issued_commands).to eq [
      'cline auth --verbose --cwd /working/dir --provider anthropic --apikey anthropic-key --modelid claude-sonnet-4-6'
    ]
  end

  it 'raises UnknownOptionError for invalid command options' do
    cli = described_class.new
    expect do
      cli.auth(invalid_option: 'value')
    end.to raise_error(Cline::Cli::UnknownOptionError, 'Unknown auth option invalid_option')
  end

  it 'returns stdout, stderr and exit_status correctly' do
    mock_commands(
      'cline auth' => {
        stdout: "Executing Cline CLI\nSuccess\n",
        stderr: "Warning: update available\n"
      }
    )
    # Mute stderr
    allow($stderr).to receive(:write)
    expect(described_class.new.auth).to eq(
      stdout: "Executing Cline CLI\nSuccess\n",
      stderr: "Warning: update available\n",
      exit_status: 0
    )
  end

  it 'raises UnexpectedExitStatusError when exit status is not expected' do
    mock_commands('cline auth' => { exit_status: 1 })
    cli = described_class.new
    expect do
      cli.auth
    end.to raise_error(Cline::Cli::UnexpectedExitStatusError)
  end

  it 'has correct cline_pid value while running command' do
    mock_commands('cline auth' => { pid: 9876, running_time_secs: 0.5 })
    cli = described_class.new
    # Create another thread to capture PID was the command is running
    captured_pid = nil
    pid_thread = Thread.new do
      # Wait a bit for cline.auth to start execution
      sleep 0.1
      captured_pid = cli.cline_pid
    end
    cli.auth
    pid_thread.join
    expect(captured_pid).to eq(9876)
  end

  it 'has nil cline_pid after running command' do
    cli = described_class.new
    cli.auth
    expect(cli.cline_pid).to be_nil
  end
end
