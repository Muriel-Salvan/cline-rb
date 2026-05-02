describe Cline::Config do
  describe '#skills' do
    it 'supports no skills information' do
      with_config_dir(skills: nil) do |config_dir|
        expect(described_class.from_dir(config_dir).skills).to be_nil
      end
    end

    it 'loads skills from the config directory' do
      with_config_dir(
        skills: {
          'test-skill-1' => {},
          'test-skill-2' => {}
        }
      ) do |config_dir|
        skills = described_class.from_dir(config_dir).skills
        expect(skills.keys).to eq %w[test-skill-1 test-skill-2]
        expect(skills['test-skill-1'].name).to eq 'test-skill-1'
        expect(skills['test-skill-2'].name).to eq 'test-skill-2'
      end
    end
  end

  describe '#data' do
    it 'loads data from the config/data directory' do
      with_config_dir(global_settings: { cline_web_tools_enabled: true }) do |config_dir|
        config = described_class.from_dir(config_dir)
        expect(config.data.global_settings.cline_web_tools_enabled).to be true
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
        config = described_class.from_dir(config_dir)
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
        config = described_class.from_dir(config_dir)
        expect(config.tasks).to be(config.data.tasks)
      end
    end

    it 'delegates global_settings' do
      with_config_dir(global_settings: { cline_web_tools_enabled: true }) do |config_dir|
        config = described_class.from_dir(config_dir)
        expect(config.global_settings).to be(config.data.global_settings)
      end
    end

    it 'delegates mcp_settings' do
      with_config_dir(
        mcp_settings: {
          mcp_servers: { server1: { disabled: false } }
        }
      ) do |config_dir|
        config = described_class.from_dir(config_dir)
        expect(config.mcp_settings).to be(config.data.mcp_settings)
      end
    end
  end

  describe '#==' do
    it 'returns true for identical configs' do
      skills = { 'test-skill' => {} }
      global_settings = { cline_web_tools_enabled: true }
      with_config_dir(skills:, global_settings: global_settings) do |config_dir1|
        config1 = described_class.from_dir(config_dir1)
        with_config_dir(skills:, global_settings: global_settings) do |config_dir2|
          config2 = described_class.from_dir(config_dir2)
          expect(config1).not_to equal(config2)
          expect(config1).to eq(config2)
        end
      end
    end

    it 'returns false for different skills' do
      with_config_dir(skills: { 'test-skill-1' => {} }) do |config_dir1|
        config1 = described_class.from_dir(config_dir1)
        with_config_dir(skills: { 'test-skill-2' => {} }) do |config_dir2|
          config2 = described_class.from_dir(config_dir2)
          expect(config1).not_to eq(config2)
        end
      end
    end

    it 'returns false for different data' do
      skills = { 'test-skill' => {} }
      with_config_dir(skills:, global_settings: { cline_web_tools_enabled: true }) do |config_dir1|
        config1 = described_class.from_dir(config_dir1)
        with_config_dir(global_settings: { cline_web_tools_enabled: false }) do |config_dir2|
          config2 = described_class.from_dir(config_dir2)
          expect(config1).not_to eq(config2)
        end
      end
    end
  end
end
