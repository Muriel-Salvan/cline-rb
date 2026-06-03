describe Cline::Config do
  describe 'delegated methods from the data directory' do
    it 'delegates global_state' do
      with_config(global_state: { clineWebToolsEnabled: true }) do |config|
        expect(config.global_state).to be config.data.global_state
      end
    end

    it 'delegates logs' do
      with_config(create: true) do |config|
        expect(config.logs).to be config.data.logs
      end
    end

    it 'delegates mcp_settings' do
      with_config(
        mcp_settings: {
          mcpServers: { server1: { disabled: false } }
        }
      ) do |config|
        expect(config.mcp_settings).to be config.data.mcp_settings
      end
    end

    it 'delegates sessions' do
      with_config(
        sessions: {
          'test-session' => {
            messages: [{ ts: 123, type: 'user', text: 'Hello' }]
          }
        }
      ) do |config|
        expect(config.sessions).to be config.data.sessions
      end
    end

    it 'delegates tasks' do
      with_config(
        tasks: {
          'my-task' => {
            messages: [{ ts: 123, type: 'user', text: 'Hello' }]
          }
        }
      ) do |config|
        expect(config.tasks).to be config.data.tasks
      end
    end

    it 'delegates providers' do
      with_config(
        providers: {
          version: 1,
          lastUsedProvider: 'openrouter'
        }
      ) do |config|
        expect(config.providers).to be config.data.providers
      end
    end

    it 'delegates workspaces' do
      with_config(
        workspaces: {
          'test-workspace' => {
            settings: {}
          }
        }
      ) do |config|
        expect(config.workspaces).to be config.data.workspaces
      end
    end
  end
end
