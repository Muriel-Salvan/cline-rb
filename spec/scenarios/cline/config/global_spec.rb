describe Cline::Config, '.global' do
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
