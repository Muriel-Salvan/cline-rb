module ClineTest
  module Helpers
    module GlobalSettings
      # Provide a test global settings instance
      #
      # @param attributes [Hash, nil] The global settings attributes to create, or nil if none
      # @param create [Boolean] Should the global settings be instantiated with the create option?
      # @yield [global_settings] Block called with the test global settings ready
      # @yieldparam [Cline::GlobalSettings] The test global settings
      def with_global_settings(attributes: nil, create: false)
        with_data(
          global_settings: attributes,
          create:
        ) do |data|
          yield data.global_settings(create:)
        end
      end
    end
  end
end
