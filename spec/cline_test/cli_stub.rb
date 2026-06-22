require 'pty_compat'

module ClineTest
  # Stub of the Cline CLI (mocking calls to PTY.spawn).
  # This can be used by external projects that need to mock or stub Cline CLI in their own unit tests.
  class CliStub
    class << self
      # Capture the original PTY.spawn method in case some test cases want to use it while the real one is mocked.
      attr_accessor :original_pty_spawn

      # @return [Boolean] The debug mode.
      attr_accessor :debug

      # Log debug a message
      #
      # @param message [String, nil] The message to log debug, or nil if given by a proc returning the message for lazy evaluation
      # @yield The optional code returning the message to log in case of debug
      # @yieldreturn [String] The message to log
      def log_debug(message = nil)
        return unless @debug

        puts "[CLINE STUB DEBUG] - #{block_given? ? yield : message}"
      end
    end
    self.original_pty_spawn = ::PTY.method(:spawn)

    # Constructor
    #
    # @param example [Object] The RSpec example for which the stub is executed
    # @param debug [Boolean] Are we in debug mode?
    # @param temp_dir [String] Temporary directory used to communicate with the stub
    def initialize(example:, debug: false, temp_dir: '.cline_test/tmp')
      @example = example
      CliStub.debug = debug
      @temp_dir = temp_dir
    end

    # Mock a list of commands, with their corresponding stdout, stderr and exit status.
    # This helper hides the underlying ways of running commands from Cline::Cli.
    # It uses a Cline CLI stub that executes mocked commands in place of the real Cline CLI.
    #
    # @param commands [Hash, Array] The description of the mocked behaviour the Cline CLI stub will have.
    #   This parameter can be of 2 kinds:
    #   - [Hash{Array<String, Regexp> => Hash{Symbol => Object}, Array<Hash{Symbol => Object}>}] Describe a list of (or a single) instructions,
    #     for each command to mock.
    #     The command to be mocked is the array of Cline arguments (after the cline executable).
    #     Each argument from this command line array can be either a String for exact match or a Regexp for pattern matching.
    #     Each mocked instruction is described below.
    #   - [Array<Hash{Symbol => Object}, Array<Hash{Symbol => Object}>>] Describe a sequential list of groups (or single) instructions.
    #     Each group of instruction will be executed for each new command that gets executed, regardless of its arguments.
    #     Each mocked instruction is described below.
    #
    #   Each instruction is a [Hash{Symbol => Object}] that describes the behaviour to mock.
    #   They are executed in sequence of the list they belong to, and in sequence of the keys inside each Hash.
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
    #       If the message's text content is a Hash with an eval key, the text content is replaced by the corresponding code execution.
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
      temp_dir = @temp_dir
      run_idx = 0
      @example.instance_eval do
        # Mock `PTY.spawn(*args) do |reader, writer, pid|` with spies pattern
        allow(::PTY).to receive(:spawn) do |*args, &block|
          cline_args = args[(args.find_index { |arg| arg.end_with?('cline') } + 1)..]
          # Find the instructions corresponding to this Cline CLI run we want to mock
          instructions =
            if commands.is_a?(Hash)
              # Ignore the verbose flag for command research if we activated the debug mode on purpose
              cline_args_search = CliStub.debug ? cline_args - ['--verbose'] : cline_args
              _mocked_command, found_instructions = commands.find do |search_command, _search_instructions|
                search_command.size == cline_args_search.size &&
                  search_command.zip(cline_args_search).all? { |search_arg, arg| search_arg.is_a?(Regexp) ? arg =~ search_arg : arg == search_arg }
              end
              found_instructions
            else
              commands[run_idx]
            end
          instructions ||= []
          # Create the JSON file that will give all instructions to execute to our Cline CLI stub.
          stub_conf_file = "#{temp_dir}/cli_stub.json"
          FileUtils.mkdir_p File.dirname(stub_conf_file)
          File.write(
            stub_conf_file,
            # Normalize instructions (always using Arrays, setting default values).
            (
              (@debug ? [{ debug: true }] : []) +
              (instructions.is_a?(Array) ? instructions : [instructions])
            ).map do |instructions_set|
              normalized_instructions = instructions_set.dup
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
                    role: 'assistant',
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
          stubbed_cmd = ["ruby#{'.exe' if OS.windows?}", File.expand_path("#{__dir__}/stubs/cline")] + cline_args
          CliStub.log_debug { "Execute `#{stubbed_cmd}` with stub conf:\n#{JSON.pretty_generate(JSON.parse(File.read(stub_conf_file)))}" }
          # In Windows' Ruby implementation (ruby.exe) there is actually a bug that splits multiline arguments into separate arguments.
          # This bug does not exist on Linux implementations.
          # Because of that, we manually replace the new lines with a magic key so that the behaviour stays consistent with the real arguments
          #   that would have been sent to Cline CLI.
          # Our stub is then doing the opposite conversion on Windows only.
          stubbed_cmd.map! { |arg| arg.gsub("\n", '__CLINE_STUB__NEW_LINE__') } if OS.windows?
          result = nil
          original_cline_stub_dir = ENV.fetch('CLINE_STUB_DIR', nil)
          ENV['CLINE_STUB_DIR'] = temp_dir
          begin
            result = CliStub.original_pty_spawn.call(*stubbed_cmd) do |reader, writer, pid|
              if @debug
                allow(reader).to receive(:each_line).and_wrap_original do |original_each_line, &each_line_block|
                  original_each_line.call do |line|
                    CliStub.log_debug "[Cline stub stdout] - #{Cline::Utils::Logger.sanitize_pty_output(line)}"
                    each_line_block.call(line)
                  end
                end
              end
              block.call(reader, writer, pid)
            end
          ensure
            ENV['CLINE_STUB_DIR'] = original_cline_stub_dir
          end
          run_idx += 1
          result
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
      calls_file = "#{@temp_dir}/cli_calls.json"
      File.exist?(calls_file) ? JSON.parse(File.read(calls_file), symbolize_names: true) : []
    end
  end
end
