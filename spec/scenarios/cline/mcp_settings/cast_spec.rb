describe Cline::McpSettings, '#cast' do
  # @return [Cline::McpSettings] An MCP settings instance to be tested
  attr_reader :mcp_settings

  around do |example|
    with_mcp_settings(create: true) do |mcp_settings|
      @mcp_settings = mcp_settings
      example.run
    end
  end

  it 'initializes mcp_servers map from Hash with McpServer entries' do
    mcp_settings.mcp_servers = {
      'server1' => {
        type: 'sse',
        url: 'http://localhost:3001',
        disabled: false,
        timeout: 30,
        auto_approve: %w[tool1 tool2]
      },
      'server2' => {
        type: 'stdio',
        disabled: true
      }
    }
    expect(mcp_settings.mcp_servers.size).to eq 2
    expect(mcp_settings.mcp_servers['server1'].type).to eq 'sse'
    expect(mcp_settings.mcp_servers['server1'].url).to eq 'http://localhost:3001'
    expect(mcp_settings.mcp_servers['server1'].disabled).to be false
    expect(mcp_settings.mcp_servers['server1'].timeout).to eq 30
    expect(mcp_settings.mcp_servers['server1'].auto_approve.size).to eq 2
    expect(mcp_settings.mcp_servers['server1'].auto_approve[0]).to eq 'tool1'
    expect(mcp_settings.mcp_servers['server2'].type).to eq 'stdio'
    expect(mcp_settings.mcp_servers['server2'].disabled).to be true
    expect(mcp_settings.mcp_servers['server2'].auto_approve).to be_nil
  end
end
