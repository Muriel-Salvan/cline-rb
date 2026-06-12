require 'json'
require 'os'
require 'stringio'

module ClineTest
  module Helpers
    module Cli
      # Mock commands and stub the CLI
      #
      # @param commands [Object] Commands to mock (see CliStub#mock_commands)
      def mock_commands(commands = {})
        @cli_stub = CliStub.new(example: self, debug: Debug.debug?)
        @cli_stub.mock_commands(commands)
      end

      # Get the list of Cline CLI commands that were issued during this test run
      #
      # @return [Array<Hash{Symbol => Object}>] List of commands that have been issued (see CliStub#issued_commands)
      def issued_commands
        @cli_stub.issued_commands
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
