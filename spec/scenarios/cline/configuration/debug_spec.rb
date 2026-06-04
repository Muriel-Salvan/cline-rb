describe Cline::Configuration, '#debug' do
  subject(:configuration) { described_class.new }

  context 'when CLINE_DEBUG environment variable is set to 1' do
    before do
      stub_const('ENV', ENV.to_h.merge('CLINE_DEBUG' => '1'))
    end

    it 'defaults to true' do
      expect(configuration.debug).to be true
    end

    it 'can be overwritten to false' do
      configuration.debug = false
      expect(configuration.debug).to be false
    end
  end

  context 'when CLINE_DEBUG environment variable is not set' do
    before do
      stub_const('ENV', ENV.to_h.except('CLINE_DEBUG'))
    end

    it 'defaults to false' do
      expect(configuration.debug).to be false
    end

    it 'can be overwritten to true' do
      configuration.debug = true
      expect(configuration.debug).to be true
    end
  end

  context 'when CLINE_DEBUG environment variable is set to a non-1 value' do
    before do
      stub_const('ENV', ENV.to_h.merge('CLINE_DEBUG' => '0'))
    end

    it 'defaults to false' do
      expect(configuration.debug).to be false
    end

    it 'can be overwritten to true' do
      configuration.debug = true
      expect(configuration.debug).to be true
    end
  end
end
