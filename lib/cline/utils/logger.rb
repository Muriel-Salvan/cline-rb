module Cline
  module Utils
    # Mixin adding some debug logging capabilities
    module Logger
      class << self
        # Global debug switch.
        attr_accessor :debug
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
