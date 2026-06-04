describe Cline do
  describe '.config' do
    it 'returns the cline-rb Rubygem configuration' do
      expect(described_class.config).not_to be_nil
      expect(described_class.config.debug).to be ClineTest::Helpers::Debug.debug?
    end

    it 'returns the configuration as a singleton instance' do
      config = described_class.config
      expect(described_class.config).to be config
    end
  end

  describe '.configure' do
    it 'yields the configuration instance' do
      described_class.configure do |config|
        expect(config).to be described_class.config
      end
    end
  end
end
