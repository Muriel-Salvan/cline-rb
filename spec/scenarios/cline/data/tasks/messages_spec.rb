describe Cline::Data, '#tasks #messages' do
  it 'returns nil when no messages.json file exists in task directory' do
    with_task(messages: nil) do |task|
      expect(task.messages).to be_nil
    end
  end

  it 'reads all attributes of the messages' do
    with_task(
      messages: [
        {
          ts: 123_456,
          type: 'assistant',
          say: 'execution_start',
          ask: 'approval',
          text: 'This is a test message',
          model_info: {
            provider_id: 'openai',
            model_id: 'gpt-4',
            mode: 'act'
          },
          conversation_history_index: 5,
          partial: false
        }
      ]
    ) do |task|
      messages = task.messages
      expect(messages.size).to eq 1
      message = messages.first
      expect(message.ts).to eq 123_456
      expect(message.timestamp).to eq Time.at(123.456)
      expect(message.type).to eq 'assistant'
      expect(message.say).to eq 'execution_start'
      expect(message.ask).to eq 'approval'
      expect(message.text).to eq 'This is a test message'
      expect(message.model_info).not_to be_nil
      expect(message.model_info.provider_id).to eq 'openai'
      expect(message.model_info.model_id).to eq 'gpt-4'
      expect(message.model_info.mode).to eq 'act'
      expect(message.conversation_history_index).to eq 5
      expect(message.partial).to be false
      expect(message.usage).to be_nil
    end
  end

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

  it 'ignores extra unknown parameters from messages.json file' do
    with_task(
      messages: [
        { ts: 123_456, type: 'user', text: 'Hello', this_is_an_unknown_parameter: 'should be ignored' },
        { ts: 123_457, type: 'assistant', text: 'Hi there', another_extra_field: 12_345 }
      ]
    ) do |task|
      messages = task.messages
      # Verify valid attributes are still correctly loaded
      expect(messages.size).to eq 2
      expect(messages.first.ts).to eq 123_456
      expect(messages.first.type).to eq 'user'
      expect(messages.first.text).to eq 'Hello'
      # Verify unknown parameters are not present on the object
      expect(messages.first).not_to respond_to(:this_is_an_unknown_parameter)
      expect(messages[1]).not_to respond_to(:another_extra_field)
    end
  end

  it 'loads all messages' do
    with_task(
      messages: [
        { ts: 100, type: 'user', text: 'First message' },
        { ts: 101, type: 'assistant', text: 'Response 1' },
        { ts: 102, type: 'user', text: 'Second question' },
        { ts: 103, type: 'assistant', text: 'Response 2' }
      ]
    ) do |task|
      messages = task.messages
      expect(messages.size).to eq 4
      expect(messages[0].ts).to eq 100
      expect(messages[1].ts).to eq 101
      expect(messages[2].ts).to eq 102
      expect(messages[3].ts).to eq 103
    end
  end
end
