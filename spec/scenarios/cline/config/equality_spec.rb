describe Cline::Config, '#==' do
  it 'returns true for identical configs' do
    skills = { 'test-skill' => {} }
    global_settings = { cline_web_tools_enabled: true }
    with_config_dir(skills:, global_settings: global_settings) do |config_dir1|
      config1 = described_class.open(config_dir1)
      with_config_dir(skills:, global_settings: global_settings) do |config_dir2|
        config2 = described_class.open(config_dir2)
        expect(config1).not_to equal(config2)
        expect(config1).to eq(config2)
      end
    end
  end

  it 'returns false for different skills' do
    with_config_dir(skills: { 'test-skill-1' => {} }) do |config_dir1|
      config1 = described_class.open(config_dir1)
      with_config_dir(skills: { 'test-skill-2' => {} }) do |config_dir2|
        config2 = described_class.open(config_dir2)
        expect(config1).not_to eq(config2)
      end
    end
  end

  it 'returns false for different data' do
    skills = { 'test-skill' => {} }
    with_config_dir(skills:, global_settings: { cline_web_tools_enabled: true }) do |config_dir1|
      config1 = described_class.open(config_dir1)
      with_config_dir(global_settings: { cline_web_tools_enabled: false }) do |config_dir2|
        config2 = described_class.open(config_dir2)
        expect(config1).not_to eq(config2)
      end
    end
  end
end
