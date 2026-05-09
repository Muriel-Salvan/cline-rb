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

  describe '.global' do
    around do |example|
      # Backup original value as it is a global cache
      original_global = described_class.instance_variable_get(:@global)
      begin
        # Clear cache
        described_class.remove_instance_variable(:@global) if described_class.instance_variable_defined?(:@global)
        with_temp_dir do |tmp_dir|
          @tmp_dir = tmp_dir.gsub('\\', '/')
          # Create .cline directory structure
          cline_dir = File.join(tmp_dir, '.cline')
          FileUtils.mkdir_p(cline_dir)
          setup_config_dir(cline_dir, global_settings: { default_terminal_profile: 'test-profile' })
          example.run
        end
      ensure
        described_class.instance_variable_set(:@global, original_global)
      end
    end

    # @return [String] The temporary directory that contains the .cline config dir
    attr_reader :tmp_dir

    context 'when the host OS is mingw32' do
      around do |example|
        with_host_os('mingw32') do
          example.call
        end
      end

      before do
        allow(ENV).to receive(:[]).with('USERPROFILE').and_return(tmp_dir)
      end

      it 'loads global config from USERPROFILE/.cline' do
        expect(described_class.global.global_settings.default_terminal_profile).to eq 'test-profile'
      end
    end

    context 'when the host OS is linux' do
      around do |example|
        with_host_os('linux') do
          example.call
        end
      end

      before do
        allow(Cline::Utils::Os).to receive(:`).with('eval echo ~$USER').and_return(tmp_dir)
      end

      it 'loads global config from HOME/.cline' do
        expect(described_class.global.global_settings.default_terminal_profile).to eq 'test-profile'
      end
    end
  end

  describe '.local' do
    around do |example|
      # Backup original value as it is a global cache
      original_local = described_class.instance_variable_get(:@local)
      begin
        # Clear cache
        described_class.remove_instance_variable(:@local) if described_class.instance_variable_defined?(:@local)
        with_temp_dir do |tmp_dir|
          tmp_dir = tmp_dir.gsub('\\', '/')
          # Create .cline directory structure
          cline_dir = File.join(tmp_dir, '.cline')
          FileUtils.mkdir_p(cline_dir)
          setup_config_dir(cline_dir, global_settings: { cline_web_tools_enabled: true })

          # Change to temporary directory for the test
          Dir.chdir(tmp_dir) do
            example.run
          end
        end
      ensure
        described_class.instance_variable_set(:@local, original_local)
      end
    end

    it 'loads local config from current working directory .cline' do
      expect(described_class.local.global_settings.cline_web_tools_enabled).to be true
    end
  end
end
