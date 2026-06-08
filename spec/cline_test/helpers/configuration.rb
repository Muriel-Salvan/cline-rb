module ClineTest
  module Helpers
    module Configuration
      # Set some cline-rb configuration settings for some execution only.
      #
      # @param config [Cline::Config] The cline-rb configuration to use.
      # @yield Code called with this configuration.
      def with_configuration(config)
        # Save old value
        original_config = Cline.config
        Cline.instance_variable_set(:@config, config)
        begin
          yield
        ensure
          Cline.instance_variable_set(:@config, original_config)
        end
      end
    end
  end
end
