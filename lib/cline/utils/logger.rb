require 'strings/ansi'

module Cline
  module Utils
    # Mixin adding some debug logging capabilities
    module Logger
      class << self
        # Global debug switch.
        attr_accessor :debug

        # Sanitize some PTY output:
        # - Remove ANSI escape codes.
        # - Remove CSI escape codes.
        # - Remove OSC escape codes.
        #
        # @param pty_output [String] PTY output string
        # @return [String] Resulting sanitized string
        def sanitize_pty_output(pty_output)
          Strings::ANSI.sanitize(pty_output).gsub(/\e\][^\a]*\a/, '')
        end
      end
      # Set default value
      Logger.debug = ENV['CLINE_DEBUG'] == '1'

      # Log a message if debug was activated
      #
      # Parameters::
      # @param msg [String, nil] Message to be displayed, or nil if the message is given lazily through a code block
      # @yield Code returning a String for lazy evaluation
      #   * Return [String] Debug message
      def log_debug(msg = nil)
        return unless Logger.debug

        msg = yield if block_given?
        puts "[CLINE DEBUG] - #{msg}"
      end
    end
  end
end
