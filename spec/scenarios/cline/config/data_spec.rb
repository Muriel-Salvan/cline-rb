describe Cline::Config, '#data' do
  it 'returns nil if the data directory does not exist' do
    with_temp_dir do |config_dir|
      expect(described_class.open(config_dir).data).to be_nil
    end
  end

  it 'loads data from the config/data directory' do
    with_config(global_settings: { clineWebToolsEnabled: true }) do |config|
      expect(config.data.global_settings.cline_web_tools_enabled).to be true
    end
  end

  it 'creates data when create: true is passed to the data method' do
    with_temp_dir do |config_dir|
      expect(described_class.open(config_dir).data(create: true)).not_to be_nil
      new_dir = File.join(config_dir, 'data')
      expect(File.exist?(new_dir)).to be true
      expect(File.directory?(new_dir)).to be true
    end
  end

  it 'creates data when config is opened with create: true' do
    with_temp_dir do |config_dir|
      expect(described_class.open(config_dir, create: true).data).not_to be_nil
      new_dir = File.join(config_dir, 'data')
      expect(File.exist?(new_dir)).to be true
      expect(File.directory?(new_dir)).to be true
    end
  end
end
