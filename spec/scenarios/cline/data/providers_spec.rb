describe Cline::Data, '#providers' do
  it 'returns nil when no providers.json file exists' do
    with_data(providers: nil) do |data|
      expect(data.providers).to be_nil
    end
  end

  it 'initializes providers when data is initialized with create option' do
    with_data(providers: nil, create: true) do |data|
      expect(data.providers).not_to be_nil
    end
  end

  it 'initializes providers when create option is given' do
    with_data(providers: nil) do |data|
      expect(data.providers(create: true)).not_to be_nil
    end
  end

  it 'loads providers from the providers.json file' do
    providers_json = {
      version: 1,
      lastUsedProvider: 'openrouter',
      providers: {
        cline: {
          settings: {
            provider: 'cline',
            apiKey: 'sk_abfe5c6e2e6dcbc1581befa0f3dc0642b13bbaf8',
            model: 'deepseek/deepseek-v4-flash'
          },
          updatedAt: '2026-06-03T14:08:53.973Z',
          tokenSource: 'manual'
        },
        openrouter: {
          settings: {
            provider: 'openrouter',
            apiKey: 'sk-or-v1-82cc3adbab12c0d892ecc69a4aafd56c35699641ba7',
            model: 'minimax/minimax-m2.5:free',
            reasoning: {
              enabled: true,
              effort: 'xhigh'
            }
          },
          updatedAt: '2026-06-03T14:10:14.358Z',
          tokenSource: 'manual'
        }
      }
    }
    with_data(providers: providers_json) do |data|
      providers = data.providers
      expect(providers).not_to be_nil
      expect(providers.version).to eq 1
      expect(providers.last_used_provider).to eq 'openrouter'
      expect(providers.providers.keys).to match_array %w[cline openrouter]
      cline_entry = providers.providers['cline']
      expect(cline_entry.settings.provider).to eq 'cline'
      expect(cline_entry.settings.api_key.to_unprotected).to eq 'sk_abfe5c6e2e6dcbc1581befa0f3dc0642b13bbaf8'
      expect(cline_entry.settings.model).to eq 'deepseek/deepseek-v4-flash'
      expect(cline_entry.updated_at).to eq '2026-06-03T14:08:53.973Z'
      expect(cline_entry.token_source).to eq 'manual'
      openrouter_entry = providers.providers['openrouter']
      expect(openrouter_entry.settings.provider).to eq 'openrouter'
      expect(openrouter_entry.settings.api_key.to_unprotected).to eq 'sk-or-v1-82cc3adbab12c0d892ecc69a4aafd56c35699641ba7'
      expect(openrouter_entry.settings.model).to eq 'minimax/minimax-m2.5:free'
      expect(openrouter_entry.settings.reasoning.enabled).to be true
      expect(openrouter_entry.settings.reasoning.effort).to eq 'xhigh'
      expect(openrouter_entry.updated_at).to eq '2026-06-03T14:10:14.358Z'
      expect(openrouter_entry.token_source).to eq 'manual'
    end
  end
end
