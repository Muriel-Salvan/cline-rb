require 'open3'
require 'stringio'

module ClineTest
  module Helpers
    module Cli
      class << self
        # Capture the original Open3.popen3 method in case some test cases want to use it while the real one is mocked.
        attr_accessor :original_popen3
      end
      self.original_popen3 = Open3.method(:popen3)

      # Mock a list of commands, with their corresponding stdout, stderr and exit status.
      # This helper hides the underlying ways of running commands from Cline::Cli.
      #
      # @param commands [Hash{String => Hash{Symbol => Object}}] For each command to mock, a description of its output:
      #   * stdout [String] The stdout to be returned for this command. Defaults to ''.
      #   * stderr [String] The stderr to be returned for this command. Defaults to ''.
      #   * exit_status [Integer] The exit status to be returned for this command. Defaults to 0.
      #   * pid [Integer, #call] The PID of the running command, or a code block that will return it lazily. Defaults to 1234.
      #     * Return [Integer] The PID to be considered.
      #   * running_time_secs [Float] The time this command runs. Defaults to 0.
      #   * eval [String] Code to be executed using an eval in the Cline process. Defaults to ''.
      #   * task [Hash{Symbol => Object}, nil] Description of a task that the Cline process should create, or nil if none. Defaults to nil.
      #     This property should be used only with a command using the --config flag.
      #     Here is the list of all properties that can be set for the task description:
      #     * messages [Array<Hash{Symbol => Object}, Array<Hash{Symbol => Object}>>, nil] List of messages (or messages groups) to be created,
      #       or nil if none.
      #       Each message (or group) from the list will be created with 0.2 seconds interval.
      def mock_commands(commands = {})
        # Mock Open3.popen3 with spies pattern
        allow(Open3).to receive(:popen3) do |cmd, &block|
          stub_conf_file = '.cline_test/tmp/cli_stub.json'
          FileUtils.mkdir_p File.dirname(stub_conf_file)
          File.write(
            stub_conf_file,
            {
              stdout: '',
              stderr: '',
              exit_status: 0,
              running_time_secs: 0,
              eval: '',
              task: nil
            }.merge(commands[cmd =~ /^(.+) < [^\s]+$/ ? Regexp.last_match(1) : cmd] || {}).to_json
          )
          stubbed_cmd = cmd.gsub(/^cline /, 'ruby spec/cline_test/stubs/cline ')
          log_debug { "Execute `#{stubbed_cmd}` with stub conf:\n#{JSON.pretty_generate(JSON.parse(File.read(stub_conf_file)))}" }
          Cli.original_popen3.call(stubbed_cmd, &block)
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
          end
        )
      end
    end
  end
end
