describe Cline::Config, '#skills' do
  it 'supports no skills information' do
    with_config_dir(skills: nil) do |config_dir|
      expect(described_class.open(config_dir).skills).to be_nil
    end
  end

  it 'loads skills from the config directory' do
    with_config_dir(
      skills: {
        'test-skill-1' => {},
        'test-skill-2' => {}
      }
    ) do |config_dir|
      skills = described_class.open(config_dir).skills
      expect(skills.keys).to eq %w[test-skill-1 test-skill-2]
      expect(skills['test-skill-1'].name).to eq 'test-skill-1'
      expect(skills['test-skill-2'].name).to eq 'test-skill-2'
    end
  end
end
