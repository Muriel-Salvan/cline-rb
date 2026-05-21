describe Cline::Config, '.open' do
  it 'returns nil if no config directory exists' do
    with_temp_dir do |temp_dir|
      expect(described_class.open(File.join(temp_dir, 'non_existent_config'))).to be_nil
    end
  end

  it 'returns a valid config when directory exists' do
    with_config do |config|
      expect(config).not_to be_nil
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
      with_config(create: true) do |config|
        expect(config).not_to be_nil
      end
    end
  end
end
