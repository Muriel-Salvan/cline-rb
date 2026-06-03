describe Cline::Providers, '#save' do
  it 'persists modified attributes to the providers.json file' do
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
        }
      }
    }
    with_providers(providers: providers_json) do |providers|
      cline_entry = providers.providers['cline']
      cline_entry.settings.model = 'deepseek/deepseek-v5'
      providers.last_used_provider = 'cline'
      providers.save
      expect(JSON.parse(File.read(File.join(providers.dir, 'settings/providers.json')))).to eq(
        'version' => 1,
        'lastUsedProvider' => 'cline',
        'providers' => {
          'cline' => {
            'settings' => {
              'provider' => 'cline',
              'apiKey' => 'sk_abfe5c6e2e6dcbc1581befa0f3dc0642b13bbaf8',
              'model' => 'deepseek/deepseek-v5'
            },
            'updatedAt' => '2026-06-03T14:08:53.973Z',
            'tokenSource' => 'manual'
          }
        }
      )
    end
  end

  it 'persists a newly instantiated providers file' do
    with_providers(providers: nil, create: true) do |providers|
      providers.version = 1
      providers.last_used_provider = 'openrouter'
      providers.providers = Cline::Utils::Schema.map(Cline::Providers::ProviderEntry).new
      providers.providers['openrouter'] = Cline::Providers::ProviderEntry.new(
        settings: Cline::Providers::ProviderSettings.new(
          provider: 'openrouter',
          api_key: Cline::SecretString.new('sk-or-test-key'),
          model: 'openai/gpt-4o'
        ),
        updated_at: '2026-06-03T15:00:00.000Z',
        token_source: 'manual'
      )
      providers.save
      expect(JSON.parse(File.read(File.join(providers.dir, 'settings/providers.json')))).to eq(
        'version' => 1,
        'lastUsedProvider' => 'openrouter',
        'providers' => {
          'openrouter' => {
            'settings' => {
              'provider' => 'openrouter',
              'apiKey' => 'sk-or-test-key',
              'model' => 'openai/gpt-4o'
            },
            'updatedAt' => '2026-06-03T15:00:00.000Z',
            'tokenSource' => 'manual'
          }
        }
      )
    end
  end

  it 'persists reasoning configuration to the providers.json file' do
    providers_json = {
      version: 1,
      lastUsedProvider: 'openrouter',
      providers: {
        openrouter: {
          settings: {
            provider: 'openrouter',
            apiKey: 'sk-or-v1-test',
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
    with_providers(providers: providers_json) do |providers|
      entry = providers.providers['openrouter']
      entry.settings.reasoning.effort = 'high'
      providers.save
      expect(JSON.parse(File.read(File.join(providers.dir, 'settings/providers.json')))).to eq(
        'version' => 1,
        'lastUsedProvider' => 'openrouter',
        'providers' => {
          'openrouter' => {
            'settings' => {
              'provider' => 'openrouter',
              'apiKey' => 'sk-or-v1-test',
              'model' => 'minimax/minimax-m2.5:free',
              'reasoning' => {
                'enabled' => true,
                'effort' => 'high'
              }
            },
            'updatedAt' => '2026-06-03T14:10:14.358Z',
            'tokenSource' => 'manual'
          }
        }
      )
    end
  end
end
