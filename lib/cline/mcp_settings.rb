module Cline
  # MCP settings
  class McpSettings < Schema
    Serializable::ClineData.include_for(self, 'settings/cline_mcp_settings.json')

    # Settings associated to 1 MCP server
    class McpServer < Schema
      # @return [Array<String>] List of tools that are automatically approved for this server
      attribute :auto_approve, Utils::Schema.collection(:string)

      # @return [Boolean] Flag indicating if this server is disabled
      attribute :disabled, :boolean

      # @return [Integer] Server timeout in seconds
      attribute :timeout, :integer

      # @return [String] Server connection type (e.g. "sse", "stdio")
      attribute :type, :string

      # @return [String] Server URL for SSE connections
      attribute :url, :string
    end

    # @return [Hash] Set of MCP servers settings
    attribute :mcp_servers, Utils::Schema.map(McpServer)
  end
end
