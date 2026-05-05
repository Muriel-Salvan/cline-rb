describe Cline::Cli do
  it 'raises UnknownOptionError for invalid global options' do
    expect do
      described_class.new(invalid_option: 'value')
    end.to raise_error(Cline::Cli::UnknownOptionError, 'Unknown global option invalid_option')
  end

  it 'has nil cline_pid before running any command' do
    cli = described_class.new
    expect(cli.cline_pid).to be_nil
  end
end
