require_relative 'shared_examples/cli_command_examples'

describe Cline::Cli, '#auth' do
  it_behaves_like(
    'a cli command',
    name: :auth,
    kwargs: {
      provider: 'openai-native',
      apikey: 'test-key-123',
      modelid: 'gpt-4o',
      baseurl: 'https://my-server.com/api'
    },
    expected_cli_command: 'auth',
    expected_cli_options: %w[--provider openai-native --apikey test-key-123 --modelid gpt-4o --baseurl https://my-server.com/api]
  )
end
