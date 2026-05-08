shared_examples 'a cli command' do |opts|
  # Possible options for opts:
  # * name [Symbol] The command name
  # * args [Array] The args that can be sent to the command. Defaults to [].
  # * kwargs [Hash] The kwargs that can be sent to the command. Defaults to {}.
  # * expected_cli [String] The expected CLI.
  # * expected_cli_options [String] The expected command line options. Defaults to ''.
  # * expected_stdin [String, nil] The expected stdin content, or nil if none. Defaults to nil.
  # Set default values
  opts.replace(
    {
      args: [],
      kwargs: {},
      cli_options: '',
      stdin: nil
    }.merge(opts)
  )

  before do
    mock_commands
  end

  it 'calls the correct command' do
    described_class.new.public_send(opts[:name], *opts[:args])
    expect_issued_commands [{ command: opts[:expected_cli], stdin: opts[:expected_stdin] }]
  end

  it 'includes global constructor options in the command' do
    described_class.new(
      verbose: true,
      cwd: '/test/path',
      config: '/test/config.yml'
    ).public_send(opts[:name], *opts[:args])
    expect_issued_commands [{ command: "#{opts[:expected_cli]} --verbose --cwd /test/path --config /test/config.yml", stdin: opts[:expected_stdin] }]
  end

  if opts[:kwargs].any?
    it 'includes command options in the command' do
      described_class.new.public_send(opts[:name], *opts[:args], **opts[:kwargs])
      expect_issued_commands [{ command: "#{opts[:expected_cli]} #{opts[:expected_cli_options]}", stdin: opts[:expected_stdin] }]
    end

    it 'combines global and command options correctly' do
      described_class.new(verbose: true, cwd: '/working/dir').public_send(opts[:name], *opts[:args], **opts[:kwargs])
      expect_issued_commands [{ command: "#{opts[:expected_cli]} --verbose --cwd /working/dir #{opts[:expected_cli_options]}", stdin: opts[:expected_stdin] }]
    end
  end

  it 'raises UnknownOptionError for invalid command options' do
    cli = described_class.new
    expect do
      cli.public_send(opts[:name], *opts[:args], invalid_option: 'value')
    end.to raise_error(Cline::Cli::UnknownOptionError, "Unknown #{opts[:name]} option invalid_option")
  end

  it 'returns stdout, stderr and exit_status correctly' do
    mock_commands(
      opts[:expected_cli] => {
        stdout: "Executing Cline CLI\nSuccess\n",
        stderr: "Warning: update available\n"
      }
    )
    # Mute stderr
    allow($stderr).to receive(:write)
    result = described_class.new.public_send(opts[:name], *opts[:args])
    expect(result[:stdout]).to eq "Executing Cline CLI\nSuccess\n"
    expect(result[:stderr]).to eq "Warning: update available\n"
    expect(result[:exit_status]).to eq 0
  end

  it 'echoes stdout content to $stdout when stdout_echo is true' do
    mock_commands(opts[:expected_cli] => { stdout: "Executing Cline CLI\nSuccess output line 1\nSuccess output line 2\n" })
    allow($stdout).to receive(:write)
    described_class.new(stdout_echo: true).public_send(opts[:name], *opts[:args])
    expect($stdout).to have_received(:write).with("Executing Cline CLI\n").ordered
    expect($stdout).to have_received(:write).with("Success output line 1\n").ordered
    expect($stdout).to have_received(:write).with("Success output line 2\n").ordered
  end

  it 'does not echo stdout content to $stdout when stdout_echo is false (default)' do
    mock_commands(opts[:expected_cli] => { stdout: "Executing Cline CLI\nSuccess\n" })
    allow($stdout).to receive(:write)
    described_class.new(stdout_echo: false).public_send(opts[:name], *opts[:args])
    expect($stdout).not_to have_received(:write)
  end

  it 'raises UnexpectedExitStatusError when exit status is not expected' do
    mock_commands(opts[:expected_cli] => { exit_status: 1 })
    cli = described_class.new
    expect do
      cli.public_send(opts[:name], *opts[:args])
    end.to raise_error(Cline::Cli::UnexpectedExitStatusError)
  end

  it 'has correct cline_pid value while running command' do
    mock_commands(opts[:expected_cli] => { pid: 9876, running_time_secs: 0.5 })
    cli = described_class.new
    # Create another thread to capture PID while the command is running
    captured_pid = nil
    pid_thread = Thread.new do
      # Wait a bit for command execution to start
      sleep 0.1
      captured_pid = cli.cline_pid
    end
    cli.public_send(opts[:name], *opts[:args])
    pid_thread.join
    expect(captured_pid).to eq(9876)
  end

  it 'has nil cline_pid after running command' do
    cli = described_class.new
    cli.public_send(opts[:name], *opts[:args])
    expect(cli.cline_pid).to be_nil
  end
end
