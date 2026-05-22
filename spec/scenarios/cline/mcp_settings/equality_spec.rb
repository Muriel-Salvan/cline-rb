describe Cline::McpSettings, '#==' do
  it 'returns true when 2 MCP settings from different data directories have the same content' do
    settings_hash = {
      mcpServers: {
        'test-server': {
          autoApprove: %w[file-read command-run],
          disabled: false,
          timeout: 30,
          type: 'stdio'
        }
      }
    }
    with_mcp_settings(mcp_settings: settings_hash) do |settings1|
      with_mcp_settings(mcp_settings: settings_hash) do |settings2|
        # Settings are from different data directories but have identical content
        expect(settings1).not_to equal(settings2) # Different instances
        expect(settings1).to eq(settings2)
      end
    end
  end

  it 'returns false when 2 MCP settings have different server attributes' do
    with_mcp_settings(mcp_settings: { mcpServers: { test: { disabled: false } } }) do |settings1|
      with_mcp_settings(mcp_settings: { mcpServers: { test: { disabled: true } } }) do |settings2|
        expect(settings1).not_to eq(settings2)
      end
    end
  end

  it 'returns false when 2 MCP settings have different server lists' do
    with_mcp_settings(mcp_settings: { mcpServers: { server1: { disabled: false } } }) do |settings1|
      with_mcp_settings(mcp_settings: { mcpServers: { server2: { disabled: false } } }) do |settings2|
        expect(settings1).not_to eq(settings2)
      end
    end
  end

  it 'returns false when 2 MCP settings have different unknown attributes' do
    with_mcp_settings(mcp_settings: { mcpServers: { server1: { unknownAttribute: 1 } } }) do |settings1|
      with_mcp_settings(mcp_settings: { mcpServers: { server2: { unknownAttribute: 2 } } }) do |settings2|
        expect(settings1).not_to eq(settings2)
      end
    end
  end
end