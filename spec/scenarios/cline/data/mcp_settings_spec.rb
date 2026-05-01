describe Cline::Data, '#mcp_settings' do
  it 'returns nil when no MCP settings file exists in data directory' do
    with_data_dir(mcp_settings: nil) do |data_dir|
      expect(described_class.from_dir(data_dir).mcp_settings).to be_nil
    end
  end

  it 'ignores extra unknown parameters from MCP settings file' do
    with_data_dir(
      mcp_settings: {
        mcp_servers: {
          'test-server': {
            auto_approve: %w[file-read command-run],
            disabled: false,
            timeout: 30,
            type: 'stdio',
            this_is_an_unknown_parameter: 'should be ignored',
            another_extra_field: 12_345
          }
        },
        top_level_unknown: 'also ignored'
      }
    ) do |data_dir|
      mcp_settings = described_class.from_dir(data_dir).mcp_settings
      # Verify valid attributes are still correctly loaded
      servers = mcp_settings.mcp_servers
      expect(servers['test-server'].auto_approve).to eq %w[file-read command-run]
      expect(servers['test-server'].disabled).to be false
      expect(servers['test-server'].timeout).to eq 30
      expect(servers['test-server'].type).to eq 'stdio'
      # Verify unknown parameters are not present on the object
      expect(servers['test-server']).not_to respond_to(:this_is_an_unknown_parameter)
      expect(servers['test-server']).not_to respond_to(:another_extra_field)
      expect(mcp_settings).not_to respond_to(:top_level_unknown)
    end
  end

  it 'loads all MCP settings attributes' do
    with_data_dir(
      mcp_settings: {
        mcp_servers: {
          'stdio-server': {
            auto_approve: %w[file-read command-run edit-files],
            disabled: false,
            timeout: 60,
            type: 'stdio'
          },
          'sse-server': {
            auto_approve: [],
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
    ) do |data_dir|
      mcp_settings = described_class.from_dir(data_dir).mcp_settings
      servers = mcp_settings.mcp_servers
      expect(servers.count).to eq 3
      # Check stdio server
      expect(servers['stdio-server'].auto_approve).to eq %w[file-read command-run edit-files]
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
