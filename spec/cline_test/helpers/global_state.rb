module ClineTest
  module Helpers
    module GlobalState
      # Provide a test global state instance
      #
      # @param attributes [Hash, nil] The global state attributes to create, or nil if none
      # @param create [Boolean] Should the global state be instantiated with the create option?
      # @yield [global_state] Block called with the test global state ready
      # @yieldparam [Cline::GlobalState] The test global state
      def with_global_state(attributes: nil, create: false)
        with_data(
          global_state: attributes,
          create:
        ) do |data|
          yield data.global_state(create:)
        end
      end
    end
  end
end
