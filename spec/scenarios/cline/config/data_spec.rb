describe Cline::Config, '#data' do
  it 'loads data from the config/data directory' do
    with_config_dir(global_settings: { cline_web_tools_enabled: true }) do |config_dir|
      config = described_class.open(config_dir)
      expect(config.data.global_settings.cline_web_tools_enabled).to be true
    end
  end
end
