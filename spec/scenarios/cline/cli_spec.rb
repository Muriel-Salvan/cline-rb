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

  it 'executes multiple commands in proper sequence' do
    mock_commands
    cli = described_class.new(verbose: true, cwd: '/test/path')
    cli.auth(provider: 'openai-native', apikey: 'test-api-key', modelid: 'gpt-4o')
    cli.task('Implement authentication system', auto_approve: true, timeout: 300, retries: 3)
    cli.task('Plan database migration', plan: true, thinking: 'high')
    cli.task('Generate documentation', json: true)
    expect_issued_commands [
      %w[auth --verbose --cwd /test/path --provider openai-native --apikey test-api-key --modelid gpt-4o],
      %w[--verbose --cwd /test/path --auto-approve --timeout 300 --retries 3] + ['Implement authentication system'],
      %w[--verbose --cwd /test/path --plan --thinking high] + ['Plan database migration'],
      %w[--verbose --cwd /test/path --json] + ['Generate documentation']
    ]
  end
end
