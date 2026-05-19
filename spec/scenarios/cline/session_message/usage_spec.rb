require 'json'

describe Cline::SessionMessage, '#usage' do
  it 'parses usage information from metrics' do
    with_session(
      messages: [
        {
          id: 'msg-1',
          role: 'assistant',
          content: [{ type: 'text', text: 'Response' }],
          ts: 123_456,
          modelInfo: {
            id: 'deepseek/deepseek-v4-flash',
            provider: 'deepseek',
            family: 'deepseek-v4'
          },
          metrics: {
            inputTokens: 1000,
            outputTokens: 500,
            cacheReadTokens: 200,
            cacheWriteTokens: 150,
            cost: 0.0025
          }
        }
      ],
      cline_models: {
        'deepseek/deepseek-v4-flash' => { 'name' => 'DeepSeek V4 Flash', 'contextWindow' => 128_000 }
      }
    ) do |session|
      usage = session.messages.first.usage
      expect(usage).not_to be_nil
      expect(usage.cost).to eq 0.0025
      expect(usage.input_tokens).to eq 1000
      expect(usage.output_tokens).to eq 500
      expect(usage.cache_read_tokens).to eq 200
      expect(usage.cache_write_tokens).to eq 150
      expect(usage.context_tokens).to eq 1850
      expect(usage.context_tokens_limit).to eq 128_000
    end
  end

  it 'uses proper model with different context token limits from other data directory' do
    messages = [
      {
        id: 'msg-1',
        role: 'assistant',
        content: [{ type: 'text', text: 'Response' }],
        ts: 100,
        modelInfo: { id: 'test/model', provider: 'test', family: 'test' },
        metrics: { inputTokens: 1000, outputTokens: 500, cost: 0.001 }
      }
    ]
    with_session(
      name: 'session-1',
      messages: messages,
      cline_models: { 'test/model' => { 'name' => 'Test Model', 'contextWindow' => 128_000 } }
    ) do |session1|
      with_session(
        name: 'session-2',
        messages: messages,
        cline_models: { 'test/model' => { 'name' => 'Test Model', 'contextWindow' => 256_000 } }
      ) do |session2|
        expect(session1.messages.first.usage.context_tokens_limit).to eq 128_000
        expect(session2.messages.first.usage.context_tokens_limit).to eq 256_000
      end
    end
  end

  it 'handles unknown model_id gracefully' do
    with_session(
      messages: [
        {
          id: 'msg-1',
          role: 'assistant',
          content: [{ type: 'text', text: 'Response' }],
          ts: 123_456,
          modelInfo: {
            id: 'unknown/model',
            provider: 'test',
            family: 'test'
          },
          metrics: {
            inputTokens: 500,
            outputTokens: 200,
            cost: 0.001
          }
        }
      ],
      cline_models: { 'known/model' => { 'name' => 'Known Model' } }
    ) do |session|
      usage = session.messages.first.usage
      expect(usage).not_to be_nil
      expect(usage.cost).to eq 0.001
      expect(usage.input_tokens).to eq 500
      expect(usage.output_tokens).to eq 200
      expect(usage.context_tokens_limit).to be_nil
      expect(usage.cline_model).to be_nil
    end
  end

  it 'returns nil when no metrics are present' do
    with_session(
      messages: [
        {
          id: 'msg-1',
          role: 'user',
          content: [{ type: 'text', text: 'Hello' }],
          ts: 100
        }
      ]
    ) do |session|
      usage = session.messages.first.usage
      expect(usage).to be_nil
    end
  end
end
