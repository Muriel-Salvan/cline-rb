require 'json'
require 'os'
require 'pty_compat'
require 'stringio'

module ClineTest
  module Helpers
    module Cli
      class << self
        # Capture the original PTY.spawn method in case some test cases want to use it while the real one is mocked.
        attr_accessor :original_pty_spawn
      end
      self.original_pty_spawn = ::PTY.method(:spawn)

      # Mock a list of commands, with their corresponding stdout, stderr and exit status.
      # This helper hides the underlying ways of running commands from Cline::Cli.
      # It uses a Cline CLI stub that executes mocked commands in place of the real Cline CLI.
      #
      # @param commands [Hash{Array<String> => Hash{Symbol => Object}, Array<Hash{Symbol => Object}>}] For each command to mock,
      #   a list of (or a single) mocked instructions.
      #   The command to be mocked is the array of Cline arguments (after the cline executable).
      #   Each mocked instruction is a Hash that describes the mocked behaviour.
      #   They are executed in sequence of the list, and keys inside each Hash.
      #   Here is the possible instructions that are available:
      #   - debug [Boolean] Set debug mode.
      #   - eval [String] Execute some code.
      #   - exit [Integer] Exit with the given exit status.
      #   - log [Hash, String] Add a line in the Cline logs, either as a JSON Hash or a raw String.
      #     This property should be used only with a command using the --config flag.
      #   - session [Hash{Symbol => Object}] Create a session.
      #     This property should be used only with a command using the --config flag.
      #     Here is the list of all properties that can be set for the session description:
      #     - Any attribute that is in a session JSON file.
      #     - messages [Array<Hash{Symbol => Object}, Array<Hash{Symbol => Object}>>, nil] List of messages (or messages groups) to be created,
      #       or nil if none.
      #       Each message (or group) from the list will be created with 0.2 seconds interval.
      #   - sleep [Float] Sleep for a given time in seconds.
      #   - stderr [String] Output a string to stderr.
      #   - stdout [String] Output a string to stdout.
      #   - task [Hash{Symbol => Object}] Create a task.
      #     This property should be used only with a command using the --config flag.
      #     Here is the list of all properties that can be set for the task description:
      #     - messages [Array<Hash{Symbol => Object}, Array<Hash{Symbol => Object}>>, nil] List of messages (or messages groups) to be created,
      #       or nil if none.
      #       Each message (or group) from the list will be created with 0.2 seconds interval.
      def mock_commands(commands = {})
        # Mock `PTY.spawn(*args) do |reader, writer, pid|` with spies pattern
        allow(::PTY).to receive(:spawn) do |*args, &block|
          # Find the mocked instructions for this Cline CLI run
          cline_args = args[(args.find_index { |arg| arg.end_with?('cline') } + 1)..]
          _mocked_command, mocked_instructions = commands.find do |search_command, _search_instructions|
            search_command.size == cline_args.size &&
              search_command.zip(cline_args).all? { |search_arg, arg| search_arg.is_a?(Regexp) ? arg =~ search_arg : arg == search_arg }
          end
          mocked_instructions ||= []
          # Create the JSON file that will give all instructions to execute to our Cline CLI stub.
          stub_conf_file = '.cline_test/tmp/cli_stub.json'
          FileUtils.mkdir_p File.dirname(stub_conf_file)
          File.write(
            stub_conf_file,
            # Normalize instructions (always using Arrays, setting default values).
            (
              (Debug.debug? ? [{ debug: true }] : []) +
              (mocked_instructions.is_a?(Array) ? mocked_instructions : [mocked_instructions])
            ).map do |instructions|
              normalized_instructions = instructions.dup
              if normalized_instructions[:log] && normalized_instructions[:log].is_a?(Hash)
                normalized_instructions[:log] = {
                  level: 30,
                  hostname: 'LOCALHOST',
                  name: 'cline.cli',
                  component: 'main',
                  properties: {
                    ulid: 'test-session-id'
                  }
                }.merge(normalized_instructions[:log])
              end
              if normalized_instructions[:session]
                normalized_instructions[:session] = {
                  version: 1,
                  session_id: 'test-session-id',
                  source: 'cli',
                  status: 'running',
                  interactive: false,
                  provider: 'cline',
                  model: 'deepseek/deepseek-v4-flash',
                  cwd: Dir.pwd,
                  workspace_root: Dir.pwd,
                  team_name: 'team-sjHpe',
                  enable_tools: true,
                  enable_spawn: true,
                  enable_teams: true
                }.merge(normalized_instructions[:session])
                if normalized_instructions[:session][:messages]
                  default_message = {
                    id: 'msg_id_1',
                    role: 'user',
                    content: [
                      {
                        type: 'text',
                        text: 'Message content'
                      }
                    ],
                    ts: 100
                  }
                  normalized_instructions[:session][:messages] = normalized_instructions[:session][:messages].map do |messages_group|
                    (messages_group.is_a?(Array) ? messages_group : [messages_group]).map { |message| default_message.merge(message) }
                  end
                end
              end
              if normalized_instructions.dig(:task, :messages)
                default_message = { ts: 100, type: 'say', say: 'text', text: 'Message content' }
                normalized_instructions[:task][:messages] = normalized_instructions[:task][:messages].map do |messages_group|
                  (messages_group.is_a?(Array) ? messages_group : [messages_group]).map { |message| default_message.merge(message) }
                end
              end
              normalized_instructions
            end.to_json
          )
          # Run PTY.spawn with our stub instead of the real Cline CLI.
          stubbed_cmd = ["ruby#{'.exe' if OS.windows?}", 'spec/cline_test/stubs/cline'] + cline_args
          log_debug { "Execute `#{stubbed_cmd}` with stub conf:\n#{JSON.pretty_generate(JSON.parse(File.read(stub_conf_file)))}" }
          # In Windows' Ruby implementation (ruby.exe) there is actually a bug that splits multiline arguments into separate arguments.
          # This bug does not exist on Linux implementations.
          # Because of that, we manually replace the new lines with '\\n' so that the behaviour stays consistent with the real arguments\
          #   that would have been sent to Cline CLI.
          # Our stub is then doing the opposite conversion on Windows only.
          stubbed_cmd.map! { |arg| arg.gsub("\n", '\\n') } if OS.windows?
          Cli.original_pty_spawn.call(*stubbed_cmd) do |reader, writer, pid|
            if Debug.debug?
              allow(reader).to receive(:each_line).and_wrap_original do |original_each_line, &each_line_block|
                original_each_line.call do |line|
                  log_debug "[Cline stub stdout] - #{Cline::Utils::Logger.sanitize_pty_output(line)}"
                  each_line_block.call(line)
                end
              end
            end
            block.call(reader, writer, pid)
          end
        end
      end

      # Get the list of Cline CLI commands that were issued during this test run
      #
      # @return [Array<Hash{Symbol => Object}>] List of commands that have been issued:
      #   * pid [Integer] The PID of the Cline process
      #   * command [Array<String>] The command itself
      #   * stdin [String, nil] The stdin that was redirected to this command, or nil if none
      def issued_commands
        calls_file = '.cline_test/tmp/cli_calls.json'
        File.exist?(calls_file) ? JSON.parse(File.read(calls_file), symbolize_names: true) : []
      end

      # Expect issued commands to match a list of commands
      #
      # @param expected_commands [Array<Array<String, Regexp>, Hash>] The expected commands or their description:
      #   * command [Array<String, Regexp>] The expected command itself (serves as the default value when used as an Array instead of a Hash).
      #       Each expected argument of the command can be either a String for exact match, or a Regexp for pattern matching.
      #   * stdin [String, nil] Expected stdin content with this command, or nil if none. Defaults to nil.
      def expect_issued_commands(expected_commands)
        # Normalize and set default values
        expected_commands = expected_commands.map do |expected_command|
          expected_command = { command: expected_command } unless expected_command.is_a?(Hash)
          {
            stdin: nil
          }.merge(expected_command)
        end
        received_commands = issued_commands.map { |command| command.slice(*%i[command stdin]) }
        log_debug "Received commands:#{JSON.pretty_generate(received_commands)}"
        log_debug "Expected commands:#{JSON.pretty_generate(expected_commands)}"
        expect(received_commands.size).to eq expected_commands.size
        received_commands.zip(expected_commands).each do |received_command, expected_command|
          expect(received_command[:command].size).to eq expected_command[:command].size
          received_command[:command].zip(expected_command[:command]).each do |received_arg, expected_arg|
            if expected_arg.is_a?(Regexp)
              expect(received_arg).to match expected_arg
            else
              expect(received_arg).to eq expected_arg
            end
          end
          expect(received_command[:stdin]).to eq expected_command[:stdin]
        end
      end

      # Run the CLI for the task command.
      # Captures all on_message calls.
      # Always run it in a temporary config directory.
      #
      # @param prompt [String, nil] The prompt to send, or nil if none
      # @param on_message [#call, nil] Optional on_message callback to provide (see Cline::Cli#task)
      # @param on_question [#call, nil] Optional on_question callback to provide (see Cline::Cli#task)
      # @param monitoring_interval_secs [Float] The monitoring interval in seconds
      # @param stub [Object] The Cline CLI stub instructions (see ClineTest::Helpers::Cli#mock_commands)
      # @param stub_ignore_prompt [Boolean] Does the stub ignore the prompt?
      # @yield Optional code called after the task command has finished
      # @yieldparam cli [Cline::Cli] The Cline CLI instance
      # @yieldparam result [Hash{Symbol => Object}] The return value of the command
      # @return [Hash{Symbol => Object}] The return value of the command
      def cli_task(prompt: 'Test prompt', on_message: nil, on_question: nil, monitoring_interval_secs: 0.05, stub: {}, stub_ignore_prompt: false)
        @messages_received = []
        result = nil
        with_config do |config|
          mock_commands(['--config', config.dir, stub_ignore_prompt ? /^.*$/ : prompt].compact => stub)
          # Create CLI instance with our test config directory
          cli = described_class.new(config: config.dir)
          result = cli.task(
            prompt,
            on_message: proc do |message, last, previous|
              @messages_received << {
                message: message,
                last: last,
                previous_version: previous
              }
              on_message&.call(message, last, previous)
            end,
            on_question:,
            monitoring_interval_secs:
          )
          yield cli, result if block_given?
        end
        result
      end

      # @return [Array<Hash{Symbol => Object}>] The list of messages that have been received by the on_message callback
      attr_reader :messages_received
    end
  end
end
