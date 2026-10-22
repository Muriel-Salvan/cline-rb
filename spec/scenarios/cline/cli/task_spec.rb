require_relative 'shared_examples/cli_command_examples'

describe Cline::Cli, '#task' do
  it_behaves_like(
    'a cli command',
    name: :task,
    args: ['Test prompt: Create a simple Ruby class'],
    kwargs: {
      plan: true,
      json: true,
      auto_approve: true,
      thinking: 'high',
      compaction: 'agentic',
      tui: true,
      id: 'session-12345',
      provider: 'openai-native',
      key: 'sk-test-key',
      model: 'gpt-4o',
      system: 'You are a helpful assistant',
      zen: true,
      retries: 3,
      timeout: 300,
      acp: true,
      data_dir: '/tmp/cline-data',
      hooks_dir: '/path/to/hooks',
      worktree: true,
      kanban: true
    },
    expected_cli_options: %w[
      --plan
      --json
      --auto-approve
      --thinking high
      --compaction agentic
      --tui
      --id session-12345
      --provider openai-native
      --key sk-test-key
      --model gpt-4o
    ] +
      ['--system', 'You are a helpful assistant'] +
      %w[
        --zen
        --retries 3
        --timeout 300
        --acp
        --data-dir /tmp/cline-data
        --hooks-dir /path/to/hooks
        --worktree
        --kanban
      ],
    expected_cli_args: ['Test prompt: Create a simple Ruby class']
  )

  it 'calls the command without any prompt' do
    cli_task(prompt: nil)
    expect_issued_commands [
      ['--config', /^.+$/]
    ]
  end

  it 'calls the command with an empty prompt' do
    cli_task(prompt: '')
    expect_issued_commands [
      ['--config', /^.+$/, '']
    ]
  end

  it 'calls the command with a 1-line prompt' do
    cli_task(prompt: '1-line test prompt')
    expect_issued_commands [
      ['--config', /^.+$/, '1-line test prompt']
    ]
  end

  it 'calls the command with a multi-line prompt' do
    cli_task(prompt: "This\nis\na\nmultiline\nprompt")
    expect_issued_commands [
      ['--config', /^.+$/, "This\nis\na\nmultiline\nprompt"]
    ]
  end

  it 'starts correctly even when the config dir does not exist' do
    mock_commands(['--config', 'unknown_config_dir', 'Test prompt'] => { sleep: 0.5 })
    described_class.new(config: 'unknown_config_dir').task('Test prompt', monitoring_interval_secs: 0.1)
    expect_issued_commands [
      ['--config', 'unknown_config_dir', 'Test prompt']
    ]
  end

  it 'starts correctly even when the config dir exists but its data dir does not exist yet' do
    # Make sure thread exceptions are not output in stdout for this test, as it messes up tests output.
    # The exception is still re-raised by Thread#join in the ensure block of Cline::Cli#task.
    original_report_on_exception = Thread.report_on_exception
    Thread.report_on_exception = false
    begin
      with_temp_dir do |config_dir|
        # The config dir exists (so Config.open returns a Config), but its data/ subdirectory does not exist yet,
        # like in a production environment where the Cline CLI has not created it yet.
        # The session monitor thread must wait for it instead of raising (see Cline::Config#logs).
        mock_commands(['--config', config_dir, 'Test prompt'] => { sleep: 0.5 })
        described_class.new(config: config_dir).task('Test prompt', monitoring_interval_secs: 0.1)
        expect_issued_commands [
          ['--config', config_dir, 'Test prompt']
        ]
      end
    ensure
      Thread.report_on_exception = original_report_on_exception
    end
  end

  describe 'prompt command line length handling' do
    context 'when the host OS is Linux' do
      around do |example|
        with_host_os('linux') do
          # Delete potential cache that could have been set before
          original_max_cmd_length = Cline::Utils::Os.instance_variable_get(:@max_cmd_length)
          Cline::Utils::Os.instance_variable_set(:@max_cmd_length, nil)
          begin
            example.run
          ensure
            Cline::Utils::Os.instance_variable_set(:@max_cmd_length, original_max_cmd_length)
          end
        end
      end

      before do
        mock_installed_os
      end

      it 'passes a short prompt directly as a CLI argument' do
        cli_task(prompt: 'Hello, please write a Ruby script')
        expect_issued_commands [
          { command: ['--config', /^.+$/, 'Hello, please write a Ruby script'] }
        ]
      end

      it 'writes a long prompt that exceeds the max command length to a temp file' do
        cli_task(
          prompt: 'x' * 95,
          stub: {
            eval: <<~EO_RUBY
              puts "[PROMPT] \#{File.read(ARGV.last.match(/The user prompt is given to you in the file `([^`]+)`\\./)[1])}"
            EO_RUBY
          },
          stub_ignore_prompt: true
        ) do |_cli, result|
          expect_issued_commands [
            { command: ['--config', /^.+$/, /^.+$/] }
          ]
          expect(result[:stdout]).to include "[PROMPT] #{'x' * 95}"
          # Validate that it is an absolute path
          file_path = issued_commands.last[:command].last.match(/The user prompt is given to you in the file `([^`]+)`\./)[1]
          expect(File.expand_path(file_path)).to eq file_path
        end
      end

      context 'when total command length fits but one argument exceeds the per-argument limit' do
        before do
          allow(Cline::Utils::Os).to receive(:`).with('getconf ARG_MAX').and_return("1000000\n")
          Cline::Utils::Os.instance_variable_set(:@max_cmd_length, nil)
          Cline::Utils::Os.instance_variable_set(:@max_arg_length, nil)
        end

        it 'writes the prompt to a temp file' do
          cli_task(
            prompt: 'x' * 200_000,
            stub: {
              eval: <<~EO_RUBY
                puts "[PROMPT] \#{File.read(ARGV.last.match(/The user prompt is given to you in the file `([^`]+)`\\./)[1])}"
              EO_RUBY
            },
            stub_ignore_prompt: true
          ) do |_cli, result|
            expect_issued_commands [
              { command: ['--config', /^.+$/, /^.+$/] }
            ]
            expect(result[:stdout].gsub("\n", '')).to include "[PROMPT] #{'x' * 200_000}"
            file_path = issued_commands.last[:command].last.match(/The user prompt is given to you in the file `([^`]+)`\./)[1]
            expect(File.expand_path(file_path)).to eq file_path
          end
        end
      end

      it 'writes a long prompt that exceeds the max command length to a temp file in a relative dir' do
        temp_config = Cline::Configuration.new
        temp_config.debug = true
        temp_config.temp_dir_root = '.cline-rb-tmp'
        with_configuration(temp_config) do
          allow($stdout).to receive(:write)
          cli_task(
            prompt: 'x' * 95,
            stub: {
              eval: <<~EO_RUBY
                puts "[PROMPT] \#{File.read(ARGV.last.match(/The user prompt is given to you in the file `([^`]+)`\\./)[1])}"
              EO_RUBY
            },
            stub_ignore_prompt: true
          ) do |_cli, result|
            expect_issued_commands [
              { command: ['--config', /^.+$/, /^.+$/] }
            ]
            expect(result[:stdout]).to include "[PROMPT] #{'x' * 95}"
            # Validate that it is an absolute path
            file_path = issued_commands.last[:command].last.match(/The user prompt is given to you in the file `([^`]+)`\./)[1]
            expect(File.expand_path(file_path)).to eq file_path
          end
        ensure
          FileUtils.rm_rf temp_config.temp_dir_root
        end
      end
    end

    context 'when the host OS is mingw32' do
      around do |example|
        with_host_os('mingw32') do
          example.run
        end
      end

      it 'passes a short prompt directly as a CLI argument' do
        cli_task(prompt: 'Hello, please write a Ruby script')
        expect_issued_commands [
          { command: ['--config', /^.+$/, 'Hello, please write a Ruby script'] }
        ]
      end

      it 'writes a long prompt that exceeds the max command length to a temp file' do
        cli_task(
          prompt: 'x' * 8200,
          stub: {
            eval: <<~EO_RUBY
              puts "[PROMPT] \#{File.read(ARGV.last.match(/The user prompt is given to you in the file `([^`]+)`\\./)[1])}"
            EO_RUBY
          },
          stub_ignore_prompt: true
        ) do |_cli, result|
          expect_issued_commands [
            { command: ['--config', /^.+$/, /^.+$/] }
          ]
          # Huge PTY output also inserts some new lines chars. Remove them to validate the output.
          expect(result[:stdout].gsub("\n", '')).to include "[PROMPT] #{'x' * 8200}"
          # Validate that it is an absolute path
          file_path = issued_commands.last[:command].last.match(/The user prompt is given to you in the file `([^`]+)`\./)[1]
          expect(File.expand_path(file_path)).to eq file_path
        end
      end

      it 'writes a long prompt that exceeds the max command length to a temp file in a relative dir' do
        temp_config = Cline::Configuration.new
        temp_config.debug = true
        temp_config.temp_dir_root = '.cline-rb-tmp'
        with_configuration(temp_config) do
          allow($stdout).to receive(:write)
          cli_task(
            prompt: 'x' * 8200,
            stub: {
              eval: <<~EO_RUBY
                puts "[PROMPT] \#{File.read(ARGV.last.match(/The user prompt is given to you in the file `([^`]+)`\\./)[1])}"
              EO_RUBY
            },
            stub_ignore_prompt: true
          ) do |_cli, result|
            expect_issued_commands [
              { command: ['--config', /^.+$/, /^.+$/] }
            ]
            # Huge PTY output also inserts some new lines chars. Remove them to validate the output.
            expect(result[:stdout].gsub("\n", '')).to include "[PROMPT] #{'x' * 8200}"
            # Validate that it is an absolute path
            file_path = issued_commands.last[:command].last.match(/The user prompt is given to you in the file `([^`]+)`\./)[1]
            expect(File.expand_path(file_path)).to eq file_path
          end
        ensure
          FileUtils.rm_rf temp_config.temp_dir_root
        end
      end
    end
  end
end
