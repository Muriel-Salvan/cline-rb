describe Cline::Data, '.open' do
  it 'returns nil if no data directory exists' do
    with_temp_dir do |temp_dir|
      expect(described_class.open(File.join(temp_dir, 'non_existent_data'))).to be_nil
    end
  end

  it 'returns a valid data when directory exists' do
    with_data do |data|
      expect(data).not_to be_nil
    end
  end

  context 'when using create option' do
    it 'creates a valid data when the data directory does not exist' do
      with_temp_dir do |temp_dir|
        new_dir = File.join(temp_dir, 'new_data')
        expect(described_class.open(new_dir, create: true)).not_to be_nil
        expect(File.exist?(new_dir)).to be true
        expect(File.directory?(new_dir)).to be true
      end
    end

    it 'returns a valid data when directory already exists' do
      with_data(create: true) do |data|
        expect(data).not_to be_nil
      end
    end
  end
end
