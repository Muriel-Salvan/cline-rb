describe Cline::Config, '#cli' do
  it 'returns a Cli instance using this config directory' do
    mock_commands
    with_config do |config|
      cli = config.cli
      cli.auth(provider: 'openai-native', apikey: 'test-api-key', modelid: 'gpt-4o')
      expect_issued_commands [
        { command: "cline auth --config #{config.dir} --provider openai-native --apikey test-api-key --modelid gpt-4o" }
      ]
    end
  end

  it 'passes global options to the Cli instance' do
    mock_commands
    with_config do |config|
      cli = config.cli(verbose: true, cwd: '/test/path')
      cli.auth(provider: 'openai-native', apikey: 'test-api-key', modelid: 'gpt-4o')
      expect_issued_commands [
        { command: "cline auth --config #{config.dir} --verbose --cwd /test/path --provider openai-native --apikey test-api-key --modelid gpt-4o" }
      ]
    end
  end
end
