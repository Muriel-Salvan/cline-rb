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
      #   * exec [#call, nil] Code to be executed when this command is run, or nil if none. Defaults to nil.
      #     This block will always be executed in a spearate thread that is then joined on the exitstatus evaluation.
      #     * Param mocked_result [Hash] The same mocked command description (see #mock_commands) that can be modified dynamically.
      def mock_commands(commands = {})
        @issued_commands = []
        # Mock Open3.popen3 with spies pattern
        allow(Open3).to receive(:popen3) do |cmd, &block|
          command, stdin =
            if cmd =~ /^(.+) < ([^\s]+)$/
              [Regexp.last_match(1), File.read(Regexp.last_match(2))]
            else
              [cmd, nil]
            end
          issued_commands << { command:, stdin: }
          mocked_result = {
            stdout: '',
            stderr: '',
            exit_status: 0,
            pid: 1234,
            running_time_secs: 0,
            exec: nil,
            exec_thread: nil
          }.merge(commands[command] || {})
          exec_thread = mocked_result[:exec] ? Thread.new { mocked_result[:exec].call(mocked_result) } : nil
          mocked_process_status = instance_double(Process::Status)
          allow(mocked_process_status).to receive(:exitstatus) do
            exec_thread&.join
            sleep mocked_result[:running_time_secs]
            mocked_result[:exit_status]
          end
          mocked_process_waiter = instance_double(
            Process::Waiter,
            value: mocked_process_status
          )
          allow(mocked_process_waiter).to receive(:pid) do
            mocked_result[:pid].is_a?(Proc) ? mocked_result[:pid].call : mocked_result[:pid]
          end
          block.call(
            instance_double(IO, close: nil),
            StringIO.new(mocked_result[:stdout]),
            StringIO.new(mocked_result[:stderr]),
            mocked_process_waiter
          )
        end
      end

      # @return [Array<Hash{Symbol => Object}>] List of commands that have been issued:
      #   * command [String] The command itself
      #   * stdin [String, nil] The stdin that was redirected to this command, or nil if none
      attr_reader :issued_commands

      # Expect issued commands to match a list of commands
      #
      # @param expected_commands [Array<String, Hash>] The expected commands or their description:
      #   * command [String] The expected command itself (serves as the default value when used as a String instead of a Hash).
      #   * stdin [String, nil] Expected stdin content with this command, or nil if none. Defaults to nil.
      def expect_issued_commands(expected_commands)
        expect(issued_commands).to eq(
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
