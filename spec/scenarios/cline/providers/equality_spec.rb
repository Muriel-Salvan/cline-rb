describe Cline::Providers, '#==' do
  it 'returns true when 2 providers objects from different data directories have the same content' do
    providers_hash = {
      version: 1,
      lastUsedProvider: 'openrouter',
      providers: {
        cline: {
          settings: {
            provider: 'cline',
            apiKey: 'sk_test_key',
            model: 'deepseek/deepseek-v4-flash'
          },
          updatedAt: '2026-06-03T14:08:53.973Z',
          tokenSource: 'manual'
        }
      }
    }
    with_providers(providers: providers_hash) do |providers1|
      with_providers(providers: providers_hash) do |providers2|
        expect(providers1).not_to equal(providers2)
        expect(providers1).to eq(providers2)
      end
    end
  end

  it 'returns false when 2 providers objects have different version' do
    with_providers(providers: { version: 1 }) do |providers1|
      with_providers(providers: { version: 2 }) do |providers2|
        expect(providers1).not_to eq(providers2)
      end
    end
  end

  it 'returns false when 2 providers objects have different last used provider' do
    with_providers(providers: { lastUsedProvider: 'openrouter' }) do |providers1|
      with_providers(providers: { lastUsedProvider: 'cline' }) do |providers2|
        expect(providers1).not_to eq(providers2)
      end
    end
  end

  it 'returns false when 2 providers objects have different provider entries' do
    with_providers(
      providers: {
        providers: {
          cline: {
            settings: { provider: 'cline', model: 'deepseek/deepseek-v4-flash' },
            updatedAt: '2026-06-03T14:08:53.973Z',
            tokenSource: 'manual'
          }
        }
      }
    ) do |providers1|
      with_providers(
        providers: {
          providers: {
            openrouter: {
              settings: { provider: 'openrouter', model: 'openai/gpt-4o' },
              updatedAt: '2026-06-03T14:10:14.358Z',
              tokenSource: 'manual'
            }
          }
        }
      ) do |providers2|
        expect(providers1).not_to eq(providers2)
      end
    end
  end

  it 'returns false when 2 providers objects have different api keys' do
    providers_hash = {
      version: 1,
      providers: {
        cline: {
          settings: { provider: 'cline', apiKey: 'sk_key_1', model: 'deepseek/deepseek-v4-flash' },
          updatedAt: '2026-06-03T14:08:53.973Z',
          tokenSource: 'manual'
        }
      }
    }
    with_providers(providers: providers_hash) do |providers1|
      modified = providers_hash.dup
      modified[:providers] = {
        cline: {
          settings: { provider: 'cline', apiKey: 'sk_key_2', model: 'deepseek/deepseek-v4-flash' },
          updatedAt: '2026-06-03T14:08:53.973Z',
          tokenSource: 'manual'
        }
      }
      with_providers(providers: modified) do |providers2|
        expect(providers1).not_to eq(providers2)
      end
    end
  end

  it 'returns false when 2 providers objects have different reasoning settings' do
    providers_hash = {
      providers: {
        openrouter: {
          settings: {
            provider: 'openrouter',
            model: 'minimax/minimax-m2.5:free',
            reasoning: { enabled: true, effort: 'xhigh' }
          },
          updatedAt: '2026-06-03T14:10:14.358Z',
          tokenSource: 'manual'
        }
      }
    }
    with_providers(providers: providers_hash) do |providers1|
      modified = providers_hash.dup
      modified[:providers] = {
        openrouter: {
          settings: {
            provider: 'openrouter',
            model: 'minimax/minimax-m2.5:free',
            reasoning: { enabled: false }
          },
          updatedAt: '2026-06-03T14:10:14.358Z',
          tokenSource: 'manual'
        }
      }
      with_providers(providers: modified) do |providers2|
        expect(providers1).not_to eq(providers2)
      end
    end
  end
end
