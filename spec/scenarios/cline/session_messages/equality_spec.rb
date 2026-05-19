describe Cline::SessionMessages, '#==' do
  it 'returns true for session messages with same content' do
    messages_attributes = {
      version: 1,
      agent: 'lead',
      messages: [
        { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'Hello' }], ts: 100 }
      ]
    }
    with_session(messages: messages_attributes) do |session1|
      with_session(name: 'session-2', messages: messages_attributes) do |session2|
        messages1 = session1.messages
        messages2 = session2.messages
        expect(messages1).not_to equal messages2
        expect(messages1).to eq messages2
      end
    end
  end

  it 'returns false for session messages with different messages content' do
    with_session(
      messages: {
        messages: [
          { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'Hello' }], ts: 100 }
        ]
      }
    ) do |session1|
      with_session(
        name: 'session-2',
        messages: {
          messages: [
            { id: 'msg-2', role: 'assistant', content: [{ type: 'text', text: 'Hi' }], ts: 200 }
          ]
        }
      ) do |session2|
        expect(session1.messages).not_to eq session2.messages
      end
    end
  end

  it 'returns false for session messages with different root attributes' do
    with_session(
      messages: {
        version: 1,
        agent: 'lead',
        messages: [
          { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'Hello' }], ts: 100 }
        ]
      }
    ) do |session1|
      with_session(
        name: 'session-2',
        messages: {
          version: 2,
          agent: 'lead',
          messages: [
            { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'Hello' }], ts: 100 }
          ]
        }
      ) do |session2|
        expect(session1.messages).not_to eq session2.messages
      end
    end
  end
end
