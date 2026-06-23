describe Cline::McpSettings, '#save' do
  it 'persists modified attributes to the cline_mcp_settings.json file' do
    with_mcp_settings(
      mcp_settings: {
        mcpServers: {
          'test-server-1': {
            autoApprove: %w[file-read command-run],
            disabled: false,
            timeout: 30,
            type: 'stdio'
          }
        }
      }
    ) do |settings|
      settings.mcp_servers['test-server-1'].disabled = true
      settings.mcp_servers['test-server-2'] = { timeout: 45 }
      settings.save
      expect(JSON.parse(File.read(File.join(settings.dir, 'settings/cline_mcp_settings.json')))).to eq(
        'mcpServers' => {
          'test-server-1' => {
            'autoApprove' => %w[file-read command-run],
            'disabled' => true,
            'timeout' => 30,
            'type' => 'stdio'
          },
          'test-server-2' => {
            'timeout' => 45
          }
        }
      )
    end
  end

  it 'persists unknown attributes to the cline_mcp_settings.json file' do
    with_mcp_settings(
      mcp_settings: {
        mcpServers: {
          'test-server-1': {
            autoApprove: %w[file-read command-run],
            disabled: false,
            timeout: 30,
            type: 'stdio',
            unknownAttribute: 'Unknown value'
          }
        }
      }
    ) do |settings|
      settings.mcp_servers['test-server-1'].disabled = true
      settings.mcp_servers['test-server-2'] = { timeout: 45 }
      settings.save
      expect(JSON.parse(File.read(File.join(settings.dir, 'settings/cline_mcp_settings.json')))).to eq(
        'mcpServers' => {
          'test-server-1' => {
            'autoApprove' => %w[file-read command-run],
            'disabled' => true,
            'timeout' => 30,
            'type' => 'stdio',
            'unknownAttribute' => 'Unknown value'
          },
          'test-server-2' => {
            'timeout' => 45
          }
        }
      )
    end
  end

  it 'persists a newly instantiated MCP settings file' do
    with_mcp_settings(mcp_settings: nil, create: true) do |settings|
      settings.mcp_servers = Cline::Utils::Schema.map(Cline::McpSettings::McpServer).new
      settings.mcp_servers['test-server'] = {
        disabled: false,
        type: 'sse',
        url: 'http://localhost:8080/sse'
      }
      settings.save
      expect(JSON.parse(File.read(File.join(settings.dir, 'settings/cline_mcp_settings.json')))).to eq(
        'mcpServers' => {
          'test-server' => {
            'disabled' => false,
            'type' => 'sse',
            'url' => 'http://localhost:8080/sse'
          }
        }
      )
    end
  end
end
