describe Cline::Config do
  describe 'initialization' do
    it 'returns nil if no config directory exists' do
      with_temp_dir do |temp_dir|
        expect(described_class.open(File.join(temp_dir, 'non_existent_config'))).to be_nil
      end
    end

    it 'returns a valid config when directory exists' do
      with_config_dir do |config_dir|
        expect(described_class.open(config_dir)).not_to be_nil
      end
    end

    context 'when using create option' do
      it 'creates a valid config when the config directory does not exist' do
        with_temp_dir do |temp_dir|
          new_dir = File.join(temp_dir, 'new_config')
          expect(described_class.open(new_dir, create: true)).not_to be_nil
          expect(File.exist?(new_dir)).to be true
          expect(File.directory?(new_dir)).to be true
        end
      end

      it 'returns a valid config when directory already exists' do
        with_config_dir do |config_dir|
          expect(described_class.open(config_dir, create: true)).not_to be_nil
        end
      end
    end
  end

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
      with_config_dir(global_settings: { clineWebToolsEnabled: true }) do |config_dir|
        config = described_class.open(config_dir)
        expect(config.global_settings).to be(config.data.global_settings)
      end
    end

    it 'delegates mcp_settings' do
      with_config_dir(
        mcp_settings: {
          mcpServers: { server1: { disabled: false } }
        }
      ) do |config_dir|
        config = described_class.open(config_dir)
        expect(config.mcp_settings).to be(config.data.mcp_settings)
      end
    end
  end
end
