describe Cline::Config, '#skills' do
  it 'returns nil if the skills directory does not exist' do
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

  it 'creates skills when create: true is passed to the skills method' do
    with_config_dir(skills: nil) do |config_dir|
      expect(described_class.open(config_dir).skills(create: true)).not_to be_nil
      new_dir = File.join(config_dir, 'skills')
      expect(File.exist?(new_dir)).to be true
      expect(File.directory?(new_dir)).to be true
    end
  end

  it 'creates skills when config is opened with create: true' do
    with_config_dir(skills: nil) do |config_dir|
      expect(described_class.open(config_dir, create: true).skills).not_to be_nil
      new_dir = File.join(config_dir, 'skills')
      expect(File.exist?(new_dir)).to be true
      expect(File.directory?(new_dir)).to be true
    end
  end
end
