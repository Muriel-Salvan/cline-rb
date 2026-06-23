describe Cline::Data, '#mcp_settings' do
  it 'returns nil when no MCP settings file exists in data directory' do
    with_data(mcp_settings: nil) do |data|
      expect(data.mcp_settings).to be_nil
    end
  end

  it 'initializes mcp_settings when data is initialized with create option' do
    with_data(mcp_settings: nil, create: true) do |data|
      expect(data.mcp_settings).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'settings/cline_mcp_settings.json'))).to be true
    end
  end

  it 'initializes mcp_settings when create option is given' do
    with_data(mcp_settings: nil) do |data|
      expect(data.mcp_settings(create: true)).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'settings/cline_mcp_settings.json'))).to be true
    end
  end

  it 'ignores extra unknown parameters from MCP settings file' do
    with_data(
      mcp_settings: {
        mcpServers: {
          'test-server': {
            autoApprove: %w[file-read command-run],
            disabled: false,
            timeout: 30,
            type: 'stdio',
            thisIsAnUnknownParameter: 'should be ignored',
            anotherExtraField: 12_345
          }
        },
        topLevelUnknown: 'also ignored'
      }
    ) do |data|
      mcp_settings = data.mcp_settings
      # Verify valid attributes are still correctly loaded
      servers = mcp_settings.mcp_servers
      expect(servers['test-server'].auto_approve.to_a).to eq %w[file-read command-run]
      expect(servers['test-server'].disabled).to be false
      expect(servers['test-server'].timeout).to eq 30
      expect(servers['test-server'].type).to eq 'stdio'
      # Verify unknown parameters are not present on the object
      expect(servers['test-server']).not_to respond_to(:this_is_an_unknown_parameter)
      expect(servers['test-server']).not_to respond_to(:thisIsAnUnknown_parameter)
      expect(servers['test-server']).not_to respond_to(:another_extra_field)
      expect(servers['test-server']).not_to respond_to(:anotherExtraField)
      expect(mcp_settings).not_to respond_to(:top_level_unknown)
      expect(mcp_settings).not_to respond_to(:topLevelUnknown)
    end
  end

  it 'loads all MCP settings attributes' do
    with_data(
      mcp_settings: {
        mcpServers: {
          'stdio-server': {
            autoApprove: %w[file-read command-run edit-files],
            disabled: false,
            timeout: 60,
            type: 'stdio'
          },
          'sse-server': {
            autoApprove: [],
            disabled: true,
            timeout: 120,
            type: 'sse',
            url: 'http://localhost:8080/sse'
          },
          'minimal-server': {
            disabled: false
          }
        }
      }
    ) do |data|
      mcp_settings = data.mcp_settings
      servers = mcp_settings.mcp_servers
      expect(servers.count).to eq 3
      # Check stdio server
      expect(servers['stdio-server'].auto_approve.to_a).to eq %w[file-read command-run edit-files]
      expect(servers['stdio-server'].disabled).to be false
      expect(servers['stdio-server'].timeout).to eq 60
      expect(servers['stdio-server'].type).to eq 'stdio'
      # Check SSE server
      expect(servers['sse-server'].auto_approve).to be_empty
      expect(servers['sse-server'].disabled).to be true
      expect(servers['sse-server'].timeout).to eq 120
      expect(servers['sse-server'].type).to eq 'sse'
      expect(servers['sse-server'].url).to eq 'http://localhost:8080/sse'
      # Check minimal server
      expect(servers['minimal-server'].disabled).to be false
    end
  end
end
