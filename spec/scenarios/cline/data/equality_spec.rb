describe Cline::Data, '#==' do
  let(:common_data) do
    {
      tasks: { 'task-1' => {}, 'task-2' => {} },
      workspaces: { 'ws-1' => { settings: { key: 'value' } } },
      cline_models: { 'model-1' => {}, 'model-2' => {} },
      global_settings: { autoUpdateEnabled: true, telemetryOptOut: false, disabledTools: %w[tool1] },
      global_state: { clineWebToolsEnabled: true, focusChainSettings: { enabled: true, remindClineInterval: 5 } },
      mcp_settings: { mcpServers: { 'server-1' => { url: 'http://localhost:9090' } } },
      secrets: { apiKey: 'my-secret-key' },
      providers: {
        version: 1,
        lastUsedProvider: 'openrouter',
        providers: {
          cline: {
            settings: {
              provider: 'cline',
              model: 'deepseek/deepseek-v4-flash'
            },
            updatedAt: '2026-06-03T14:08:53.973Z',
            tokenSource: 'manual'
          }
        }
      },
      logs: [{ timestamp: '2024-01-01T00:00:00Z', message: 'test log' }]
    }
  end

  it 'returns true for identical data' do
    with_data(**common_data) do |data1|
      with_data(**common_data) do |data2|
        expect(data1).not_to equal(data2)
        expect(data1).to eq(data2)
      end
    end
  end

  it 'returns false for different tasks' do
    with_data(**common_data) do |data1|
      with_data(**common_data, tasks: { 'task-3' => {} }) do |data2|
        expect(data1).not_to eq(data2)
      end
    end
  end

  it 'returns false for different workspaces' do
    with_data(**common_data) do |data1|
      with_data(**common_data, workspaces: { 'ws-2' => { settings: { other_key: 'other_value' } } }) do |data2|
        expect(data1).not_to eq(data2)
      end
    end
  end

  it 'returns false for different cline_models' do
    with_data(**common_data) do |data1|
      with_data(**common_data, cline_models: { 'model-3' => {} }) do |data2|
        expect(data1).not_to eq(data2)
      end
    end
  end

  it 'returns false for different global state' do
    with_data(**common_data) do |data1|
      with_data(**common_data, global_state: { clineWebToolsEnabled: false }) do |data2|
        expect(data1).not_to eq(data2)
      end
    end
  end

  it 'returns false for different global settings' do
    with_data(**common_data) do |data1|
      with_data(**common_data, global_settings: { autoUpdateEnabled: false }) do |data2|
        expect(data1).not_to eq(data2)
      end
    end
  end

  it 'returns false for different mcp settings' do
    with_data(**common_data) do |data1|
      with_data(**common_data, mcp_settings: { mcpServers: { 'server-2' => { url: 'http://localhost:8080' } } }) do |data2|
        expect(data1).not_to eq(data2)
      end
    end
  end

  it 'returns false for different secrets' do
    with_data(**common_data) do |data1|
      with_data(**common_data, secrets: { apiKey: 'different-secret' }) do |data2|
        expect(data1).not_to eq(data2)
      end
    end
  end

  it 'returns false for different providers' do
    with_data(**common_data) do |data1|
      with_data(**common_data, providers: { version: 2 }) do |data2|
        expect(data1).not_to eq(data2)
      end
    end
  end

  it 'returns true for different logs' do
    with_data(**common_data) do |data1|
      with_data(**common_data, logs: [{ timestamp: '2025-06-01T12:00:00Z', message: 'different log' }]) do |data2|
        expect(data1).to eq(data2)
      end
    end
  end
end
