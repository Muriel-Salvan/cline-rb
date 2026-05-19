module ClineTest
  module Helpers
    module Session
      # Provide a test session
      #
      # @param name [String] The session name (also serves as session_id)
      # @param data [Hash, nil] The session data attributes, or nil if none
      # @param messages [Hash, nil] The full messages JSON file content, or nil if none
      # @param cline_models [Hash{String => Hash}, nil] The Cline models to create, or nil if none
      # @param create [Boolean] Should the data be instantiated with the create option?
      # @yield [session] Block called with the test session ready
      # @yieldparam [Cline::Session] The test session
      def with_session(name: 'test-session', data: nil, messages: nil, cline_models: nil, create: false)
        with_data(
          sessions: {
            name => {
              data:,
              messages:
            }
          },
          cline_models:,
          create:
        ) do |data_obj|
          yield data_obj.sessions[name]
        end
      end
    end
  end
end
