module ClineTest
  module Helpers
    module Secrets
      # Provide a test secrets instance
      #
      # @param secrets [Hash, nil] The secrets attributes to create, or nil if none
      # @param create [Boolean] Should the secrets be instantiated with the create option?
      # @yield [secrets] Block called with the test secrets ready
      # @yieldparam [Cline::Secrets] The test secrets
      def with_secrets(secrets: nil, create: false)
        with_data(
          secrets:,
          create:
        ) do |data|
          yield data.secrets(create:)
        end
      end
    end
  end
end
