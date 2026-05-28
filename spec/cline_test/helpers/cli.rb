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
      # @param commands [Hash{String => Hash{Symbol => Object}, Array<Hash{Symbol => Object}>}] For each command to mock,
      #   a list of (or a single) mocked instructions.
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
        # Mock `PTY.spawn(cmd) do |reader, writer, pid|` with spies pattern
        allow(::PTY).to receive(:spawn) do |cmd, &block|
          # Find the mocked instructions for this Cline CLI run
          cline_args = cmd.match(/^cline(.cmd)? (.+)$/)[2]
          mocked_instructions = commands[(cline_args =~ /^(.+) < [^\s]+$/ ? Regexp.last_match(1) : cline_args).strip] || []
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
          stubbed_cmd = "ruby#{'.exe' if OS.windows?} spec/cline_test/stubs/cline #{cline_args}"
          log_debug { "Execute `#{stubbed_cmd}` with stub conf:\n#{JSON.pretty_generate(JSON.parse(File.read(stub_conf_file)))}" }
          Cli.original_pty_spawn.call(stubbed_cmd) do |reader, writer, pid|
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
      #   * command [String] The command itself
      #   * stdin [String, nil] The stdin that was redirected to this command, or nil if none
      def issued_commands
        calls_file = '.cline_test/tmp/cli_calls.json'
        File.exist?(calls_file) ? JSON.parse(File.read(calls_file), symbolize_names: true) : []
      end

      # Expect issued commands to match a list of commands
      #
      # @param expected_commands [Array<String, Hash>] The expected commands or their description:
      #   * command [String] The expected command itself (serves as the default value when used as a String instead of a Hash).
      #   * stdin [String, nil] Expected stdin content with this command, or nil if none. Defaults to nil.
      def expect_issued_commands(expected_commands)
        expect(issued_commands.map { |command| command.slice(*%i[command stdin]) }).to eq(
          expected_commands.map do |expected_command|
            # Normalize and set default values
            {
              stdin: nil
            }.merge(expected_command.is_a?(Hash) ? expected_command : { command: expected_command })
              .merge(command: expected_command[:command].strip)
          end
        )
      end

      # Run the CLI for the task command.
      # Captures all on_message calls.
      # Always run it in a temporary config directory.
      #
      # @param stub [Object] The Cline CLI stub instructions (see ClineTest::Helpers::Cli#mock_commands)
      # @param prompt [String] The prompt to send
      # @param on_message [#call, nil] Optional on_message callback to provide (see Cline::Cli#task)
      # @param monitoring_interval_secs [Float] The monitoring interval in seconds
      # @yield Optional code called after the task command has finished
      # @yieldparam cli [Cline::Cli] The Cline CLI instance
      # @yieldparam result [Hash{Symbol => Object}] The return value of the command
      # @return [Hash{Symbol => Object}] The return value of the command
      def cli_task(prompt: 'Test prompt', on_message: nil, monitoring_interval_secs: 0.05, stub: {})
        @messages_received = []
        result = nil
        with_config do |config|
          mock_commands("--config #{config.dir} #{prompt}" => stub)
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
