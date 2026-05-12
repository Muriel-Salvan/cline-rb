describe Cline::Config do
  describe 'delegated methods from the data directory' do
    it 'delegates workspaces' do
      with_config_dir(
        workspaces: {
          'test-workspace' => {
            settings: {}
          }
        }
      ) do |config_dir|
        config = described_class.open(config_dir)
        expect(config.workspaces).to be(config.data.workspaces)
      end
    end

    it 'delegates tasks' do
      with_config_dir(
        tasks: {
          'my-task' => {
            messages: [{ ts: 123, type: 'user', text: 'Hello' }]
          }
        }
      ) do |config_dir|
        config = described_class.open(config_dir)
        expect(config.tasks).to be(config.data.tasks)
      end
    end

    it 'delegates global_settings' do
      with_config_dir(global_settings: { cline_web_tools_enabled: true }) do |config_dir|
        config = described_class.open(config_dir)
        expect(config.global_settings).to be(config.data.global_settings)
      end
    end

    it 'delegates mcp_settings' do
      with_config_dir(
        mcp_settings: {
          mcp_servers: { server1: { disabled: false } }
        }
      ) do |config_dir|
        config = described_class.open(config_dir)
        expect(config.mcp_settings).to be(config.data.mcp_settings)
      end
    end
  end
end
