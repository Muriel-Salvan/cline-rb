shared_examples 'a cli command' do |opts|
  # Possible options for opts:
  # - name [Symbol] The command name
  # - args [Array] The args that can be sent to the command. Defaults to [].
  # - kwargs [Hash] The kwargs that can be sent to the command. Defaults to {}.
  # - expected_cli_command [String, nil] The expected CLI command, or nil if none. Defaults to nil.
  # - expected_cli_options [Array<String>] The expected command line options. Defaults to [].
  # - expected_cli_args [Array<String>] The expected command line extra arguments. Defaults to [].
  # - expected_stdin [String, nil] The expected stdin content, or nil if none. Defaults to nil.
  # Set default values
  opts.replace(
    {
      args: [],
      kwargs: {},
      cli_options: '',
      stdin: nil,
      expected_cli_command: nil,
      expected_cli_options: [],
      expected_cli_args: []
    }.merge(opts)
  )

  before do
    mock_commands
  end

  it 'calls the correct command' do
    described_class.new.public_send(opts[:name], *opts[:args])
    expect_issued_commands [{ command: ([opts[:expected_cli_command]] + opts[:expected_cli_args]).compact, stdin: opts[:expected_stdin] }]
  end

  it 'includes global constructor options in the command' do
    with_config do |config|
      described_class.new(
        verbose: true,
        cwd: '/test/path',
        config: config.dir
      ).public_send(opts[:name], *opts[:args])
      expect_issued_commands [
        {
          command: ([opts[:expected_cli_command]] + %w[--verbose --cwd /test/path --config] + [config.dir] + opts[:expected_cli_args]).compact,
          stdin: opts[:expected_stdin]
        }
      ]
    end
  end

  if opts[:kwargs].any?
    it 'includes command options in the command' do
      described_class.new.public_send(opts[:name], *opts[:args], **opts[:kwargs])
      expect_issued_commands [
        {
          command: ([opts[:expected_cli_command]] + opts[:expected_cli_options] + opts[:expected_cli_args]).compact,
          stdin: opts[:expected_stdin]
        }
      ]
    end

    it 'combines global and command options correctly' do
      described_class.new(verbose: true, cwd: '/working/dir').public_send(opts[:name], *opts[:args], **opts[:kwargs])
      expect_issued_commands [
        {
          command: ([opts[:expected_cli_command]] + %w[--verbose --cwd /working/dir] + opts[:expected_cli_options] + opts[:expected_cli_args]).compact,
          stdin: opts[:expected_stdin]
        }
      ]
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
      ([opts[:expected_cli_command]] + opts[:expected_cli_args]).compact => {
        stdout: "Executing Cline CLI\nSuccess\n",
        stderr: "Warning: update available\n"
      }
    )
    result = described_class.new.public_send(opts[:name], *opts[:args])
    expect(result[:stdout].gsub("\r\n", "\n")).to include "Executing Cline CLI\nSuccess\nWarning: update available\n"
    expect(result[:exit_status]).to eq 0
  end

  it 'echoes stdout content to $stdout when stdout_echo is true' do
    mock_commands(
      ([opts[:expected_cli_command]] + opts[:expected_cli_args]).compact => {
        stdout: "Executing Cline CLI\nSuccess output line 1\nSuccess output line 2\n"
      }
    )
    received_stdout = []
    allow($stdout).to receive(:write) do |received_data|
      received_stdout << Cline::Utils::Logger.sanitize_pty_output(received_data).gsub("\r\n", "\n")
    end
    described_class.new(stdout_echo: true).public_send(opts[:name], *opts[:args])
    expect(received_stdout.join).to include <<~EO_STDOUT.gsub("\r\n", "\n")
      Executing Cline CLI
      Success output line 1
      Success output line 2
    EO_STDOUT
  end

  it 'does not echo stdout content to $stdout when stdout_echo is false (default)' do
    mock_commands(([opts[:expected_cli_command]] + opts[:expected_cli_args]).compact => { stdout: "Executing Cline CLI\nSuccess\n" })
    stdout_messages = []
    allow($stdout).to receive(:write) do |message|
      stdout_messages << message
    end
    described_class.new(stdout_echo: false).public_send(opts[:name], *opts[:args])
    # Check that every call was only made for debug logs if any
    expect(
      stdout_messages.reject do |message|
        message.start_with?('[CLINE DEBUG] - ') ||
          message.start_with?('[CLINE TEST DEBUG] - ')
      end
    ).to be_empty
  end

  it 'raises UnexpectedExitStatusError when exit status is not expected' do
    mock_commands(([opts[:expected_cli_command]] + opts[:expected_cli_args]).compact => { exit: 1 })
    cli = described_class.new
    expect do
      cli.public_send(opts[:name], *opts[:args])
    end.to raise_error(Cline::Cli::UnexpectedExitStatusError)
  end

  it 'has correct cline_pid value while running command' do
    mock_commands(([opts[:expected_cli_command]] + opts[:expected_cli_args]).compact => { sleep: 1 })
    cli = described_class.new
    # Create another thread to capture PID while the command is running
    captured_pids = nil
    pid_thread = Thread.new do
      # Wait a bit for command execution to start
      sleep 0.1 until cli.cline_pid
      captured_pids = [cli.cline_pid] + get_child_pids_recursive(cli.cline_pid)
    end
    cli.public_send(opts[:name], *opts[:args])
    pid_thread.join
    # The PID of the command Ruby process should be part of children (inclusive) of cline_pid
    expect(captured_pids).to include(issued_commands.first[:pid])
  end

  it 'has nil cline_pid after running command' do
    cli = described_class.new
    cli.public_send(opts[:name], *opts[:args])
    expect(cli.cline_pid).to be_nil
  end
end
