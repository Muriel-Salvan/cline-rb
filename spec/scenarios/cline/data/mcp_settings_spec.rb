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
    ) do |data|
      mcp_settings = data.mcp_settings
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
    with_data(
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
    ) do |data|
      mcp_settings = data.mcp_settings
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

  describe '#save' do
    it 'persists modified attributes to the cline_mcp_settings.json file' do
      with_data(
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
      ) do |data|
        settings = data.mcp_settings
        settings.mcp_servers['test-server-1'].disabled = true
        settings.mcp_servers['test-server-2'] = Cline::McpSettings::McpServer.new(timeout: 45)
        settings.save
        file_content = JSON.parse(File.read(File.join(data.dir, 'settings/cline_mcp_settings.json')))
        expect(file_content['mcpServers']['test-server-1']['disabled']).to be true
        expect(file_content['mcpServers']['test-server-1']['autoApprove']).to eq %w[file-read command-run]
        expect(file_content['mcpServers']['test-server-1']['timeout']).to eq 30
        expect(file_content['mcpServers']['test-server-1']['type']).to eq 'stdio'
        expect(file_content['mcpServers']['test-server-1']['unknownAttribute']).to eq 'Unknown value'
        expect(file_content['mcpServers']['test-server-2']['timeout']).to eq 45
      end
    end

    it 'persists a newly instantiated MCP settings file' do
      with_data(mcp_settings: nil) do |data|
        settings = data.mcp_settings(create: true)
        settings.mcp_servers = Cline::Utils::Schema.map(Cline::McpSettings::McpServer).new
        settings.mcp_servers['test-server'] = Cline::McpSettings::McpServer.new(
          disabled: false,
          type: 'sse',
          url: 'http://localhost:8080/sse'
        )
        settings.save
        expect(JSON.parse(File.read(File.join(data.dir, 'settings/cline_mcp_settings.json')))).to eq(
          'mcpServers' => {
            'test-server' => {
              'autoApprove' => [],
              'disabled' => false,
              'type' => 'sse',
              'url' => 'http://localhost:8080/sse'
            }
          }
        )
      end
    end
  end

  describe '#==' do
    it 'returns true when 2 MCP settings from different data directories have the same content' do
      settings_hash = {
        mcp_servers: {
          'test-server': {
            auto_approve: %w[file-read command-run],
            disabled: false,
            timeout: 30,
            type: 'stdio'
          }
        }
      }
      with_data(mcp_settings: settings_hash) do |data1|
        settings1 = data1.mcp_settings
        with_data(mcp_settings: settings_hash) do |data2|
          settings2 = data2.mcp_settings
          # Settings are from different data directories but have identical content
          expect(settings1).not_to equal(settings2) # Different instances
          expect(settings1).to eq(settings2)
        end
      end
    end

    it 'returns false when 2 MCP settings have different server attributes' do
      with_data(mcp_settings: { mcp_servers: { test: { disabled: false } } }) do |data1|
        with_data(mcp_settings: { mcp_servers: { test: { disabled: true } } }) do |data2|
          expect(data1.mcp_settings).not_to eq(data2.mcp_settings)
        end
      end
    end

    it 'returns false when 2 MCP settings have different server lists' do
      with_data(mcp_settings: { mcp_servers: { server1: { disabled: false } } }) do |data1|
        with_data(mcp_settings: { mcp_servers: { server2: { disabled: false } } }) do |data2|
          expect(data1.mcp_settings).not_to eq(data2.mcp_settings)
        end
      end
    end

    it 'returns false when 2 MCP settings have different unknown attributes' do
      with_data(mcp_settings: { mcp_servers: { server1: { unknown_attribute: 1 } } }) do |data1|
        with_data(mcp_settings: { mcp_servers: { server2: { unknown_attribute: 2 } } }) do |data2|
          expect(data1.mcp_settings).not_to eq(data2.mcp_settings)
        end
      end
    end
  end
end
