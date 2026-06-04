describe Cline::Configuration, '#temp_dir_root' do
  subject(:configuration) { described_class.new }

  it 'defaults to .cline-rb/tmp' do
    expect(configuration.temp_dir_root).to eq '.cline-rb/tmp'
  end

  it 'can be overwritten' do
    configuration.temp_dir_root = '/tmp/my-debug'
    expect(configuration.temp_dir_root).to eq '/tmp/my-debug'
  end
end
