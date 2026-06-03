module ClineTest
  module Helpers
    module Providers
      # Provide a test providers instance
      #
      # @param providers [Hash, nil] The providers attributes to create, or nil if none
      # @param create [Boolean] Should the providers be instantiated with the create option?
      # @yield [providers] Block called with the test providers ready
      # @yieldparam [Cline::Providers] The test providers
      def with_providers(providers: nil, create: false)
        with_data(
          providers:,
          create:
        ) do |data|
          yield data.providers(create:)
        end
      end
    end
  end
end
