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
