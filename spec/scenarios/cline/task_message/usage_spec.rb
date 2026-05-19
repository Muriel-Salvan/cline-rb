describe Cline::TaskMessage, '#usage' do
  it 'parses usage information from api_req_started messages' do
    with_task(
      messages: [
        {
          ts: 123_456,
          type: 'say',
          say: 'api_req_started',
          text: JSON.generate(
            {
              cost: 0.0025,
              tokensIn: 1000,
              tokensOut: 500,
              cacheReads: 200,
              cacheWrites: 150
            }
          ),
          model_info: {
            provider_id: 'openai',
            model_id: 'gpt-4',
            mode: 'act'
          }
        }
      ],
      cline_models: {
        'gpt-4' => { 'name' => 'GPT-4', 'contextWindow' => 128_000 }
      }
    ) do |task|
      usage = task.messages.first.usage
      expect(usage).not_to be_nil
      expect(usage.cost).to eq(0.0025)
      expect(usage.input_tokens).to eq(1000)
      expect(usage.output_tokens).to eq(500)
      expect(usage.cache_read_tokens).to eq(200)
      expect(usage.cache_write_tokens).to eq(150)
      expect(usage.context_tokens).to eq(1850)
      expect(usage.context_tokens_limit).to eq(128_000)
    end
  end

  it 'uses proper model with different context token limits from other data directory' do
    messages = [
      {
        type: 'say',
        say: 'api_req_started',
        text: JSON.generate({ tokensIn: 1000, tokensOut: 500 }),
        model_info: { model_id: 'test/model' }
      }
    ]
    with_task(
      messages: messages,
      cline_models: { 'test/model' => { 'name' => 'Test Model', 'contextWindow' => 128_000 } }
    ) do |task1|
      with_task(
        name: 'other-task',
        messages: messages,
        cline_models: { 'test/model' => { 'name' => 'Test Model', 'contextWindow' => 256_000 } }
      ) do |task2|
        expect(task1.messages.first.usage.context_tokens_limit).to eq(128_000)
        expect(task2.messages.first.usage.context_tokens_limit).to eq(256_000)
      end
    end
  end

  it 'handles unknown model_id gracefully' do
    with_task(
      messages: [
        {
          type: 'say',
          say: 'api_req_started',
          text: JSON.generate(
            {
              cost: 0.001,
              tokensIn: 500,
              tokensOut: 200
            }
          ),
          model_info: {
            provider_id: 'test',
            model_id: 'unknown/model',
            mode: 'act'
          }
        }
      ],
      cline_models: { 'known/model' => { 'name' => 'Known Model' } }
    ) do |task|
      usage = task.messages.first.usage
      expect(usage).not_to be_nil
      expect(usage.cost).to eq(0.001)
      expect(usage.input_tokens).to eq(500)
      expect(usage.output_tokens).to eq(200)
      expect(usage.context_tokens_limit).to be_nil
      expect(usage.cline_model).to be_nil
    end
  end
end
