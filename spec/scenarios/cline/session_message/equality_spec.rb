describe Cline::SessionMessage, '#==' do
  it 'returns true for messages with same content even with different cline_models instances' do
    message_data = {
      id: 'msg-1',
      role: 'assistant',
      content: [
        { type: 'text', text: 'Hello world' }
      ],
      ts: 123_456,
      modelInfo: {
        id: 'test/model',
        provider: 'test',
        family: 'test-family'
      }
    }
    with_session(
      name: 'session-1',
      messages: [message_data],
      cline_models: { 'test/model' => { 'name' => 'Test Model 1', 'contextWindow' => 128_000 } }
    ) do |session1|
      with_session(
        name: 'session-2',
        messages: [message_data],
        cline_models: { 'test/model' => { 'name' => 'Test Model 2', 'contextWindow' => 256_000 } }
      ) do |session2|
        message1 = session1.messages.first
        message2 = session2.messages.first
        expect(message1.cline_models).not_to equal message2.cline_models
        expect(message1).to eq message2
      end
    end
  end

  it 'returns true for messages with same content blocks' do
    with_session(
      messages: [
        { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'Hello' }], ts: 100 }
      ]
    ) do |session1|
      with_session(
        name: 'session-2',
        messages: [
          { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'Hello' }], ts: 100 }
        ]
      ) do |session2|
        expect(session1.messages.first).to eq session2.messages.first
      end
    end
  end

  it 'returns false for messages with different content blocks' do
    with_session(
      messages: [
        { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'Hello' }], ts: 100 }
      ]
    ) do |session1|
      with_session(
        name: 'session-2',
        messages: [
          { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'Different' }], ts: 100 }
        ]
      ) do |session2|
        expect(session1.messages.first).not_to eq session2.messages.first
      end
    end
  end
end
