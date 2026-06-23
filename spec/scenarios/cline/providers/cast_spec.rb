describe Cline::Providers, '#cast' do
  # @return [Cline::Providers] A providers instance to be tested
  attr_reader :providers

  around do |example|
    with_providers(create: true) do |providers|
      @providers = providers
      example.run
    end
  end

  it 'initializes providers map from Hash with ProviderEntry entries' do
    providers.providers = {
      'openai' => {
        settings: {
          provider: 'openai',
          api_key: 'sk-test-key',
          model: 'gpt-4',
          reasoning: {
            enabled: true,
            effort: 'xhigh'
          }
        },
        updated_at: '2024-01-01',
        token_source: 'manual'
      },
      'anthropic' => {
        settings: {
          provider: 'anthropic',
          api_key: 'sk-ant-test-key',
          model: 'claude-3'
        },
        updated_at: '2024-01-02',
        token_source: 'manual'
      }
    }
    expect(providers.providers.size).to eq 2
    expect(providers.providers['openai'].settings.provider).to eq 'openai'
    expect(providers.providers['openai'].settings.api_key.to_unprotected).to eq 'sk-test-key'
    expect(providers.providers['openai'].settings.model).to eq 'gpt-4'
    expect(providers.providers['openai'].settings.reasoning.enabled).to be true
    expect(providers.providers['openai'].settings.reasoning.effort).to eq 'xhigh'
    expect(providers.providers['openai'].updated_at).to eq '2024-01-01'
    expect(providers.providers['openai'].token_source).to eq 'manual'
    expect(providers.providers['anthropic'].settings.provider).to eq 'anthropic'
    expect(providers.providers['anthropic'].settings.api_key.to_unprotected).to eq 'sk-ant-test-key'
    expect(providers.providers['anthropic'].settings.model).to eq 'claude-3'
    expect(providers.providers['anthropic'].settings.reasoning).to be_nil
    expect(providers.providers['anthropic'].updated_at).to eq '2024-01-02'
    expect(providers.providers['anthropic'].token_source).to eq 'manual'
  end
end
