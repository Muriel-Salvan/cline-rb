module ClineTest
  module Helpers
    module McpSettings
      # Provide a test MCP settings instance
      #
      # @param mcp_settings [Hash, nil] The MCP settings attributes to create, or nil if none
      # @param create [Boolean] Should the MCP settings be instantiated with the create option?
      # @yield [mcp_settings] Block called with the test MCP settings ready
      # @yieldparam [Cline::McpSettings] The test MCP settings
      def with_mcp_settings(mcp_settings: nil, create: false)
        with_data(
          mcp_settings:,
          create:
        ) do |data|
          yield data.mcp_settings(create:)
        end
      end
    end
  end
end
