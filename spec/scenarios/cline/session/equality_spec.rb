describe Cline::Session, '#==' do
  it 'returns true when 2 sessions from different data directories have the same data' do
    data_attributes = {
      session_id: 'test-session',
      source: 'cli',
      status: 'completed',
      provider: 'cline',
      model: 'deepseek/deepseek-v4-flash'
    }
    with_session(data: data_attributes) do |session1|
      with_session(name: 'test-session-2', data: data_attributes) do |session2|
        # Sessions are from different data directories but have identical data
        expect(session1).not_to equal session2 # Different instances
        expect(session1).to eq session2
        expect(session1.data).not_to equal session2.data
        expect(session1.data).to eq session2.data
      end
    end
  end

  it 'returns false when 2 sessions have different data attributes' do
    with_session(data: { session_id: 'session-1', source: 'cli' }) do |session1|
      with_session(name: 'session-2', data: { session_id: 'session-2', source: 'web' }) do |session2|
        expect(session1).not_to eq session2
        expect(session1.data).not_to eq session2.data
      end
    end
  end

  it 'returns false when 2 sessions have different data attributes that are unknown' do
    with_session(data: { session_id: 'test', unknown_attribute: 1 }) do |session1|
      with_session(name: 'session-2', data: { session_id: 'test', unknown_attribute: 2 }) do |session2|
        expect(session1).not_to eq session2
        expect(session1.data).not_to eq session2.data
      end
    end
  end

  it 'returns true when 2 sessions from different data directories have the same messages' do
    messages_attributes = {
      agent: 'lead',
      messages: [
        {
          id: 'msg-1',
          role: 'user',
          content: [{ type: 'text', text: 'Hello' }],
          ts: 1_700_000_000_000
        },
        {
          id: 'msg-2',
          role: 'assistant',
          content: [{ type: 'text', text: 'Hi there!' }],
          ts: 1_700_000_000_001
        }
      ]
    }
    with_session(messages: messages_attributes) do |session1|
      with_session(name: 'test-session-2', messages: messages_attributes) do |session2|
        # Sessions are from different data directories but have identical messages
        expect(session1).not_to equal session2 # Different instances
        expect(session1).to eq session2
        expect(session1.messages).not_to equal session2.messages
        expect(session1.messages).to eq session2.messages
      end
    end
  end

  it 'returns false when 2 sessions have different messages attributes' do
    with_session(messages: { agent: 'lead', messages: [{ id: 'msg-1', ts: 1_700_000_000_000 }] }) do |session1|
      with_session(name: 'session-2', messages: { agent: 'user', messages: [{ id: 'msg-1', ts: 1_700_000_000_000 }] }) do |session2|
        expect(session1).not_to eq session2
        expect(session1.messages).not_to eq session2.messages
      end
    end
  end

  it 'returns false when 2 sessions have different root messages attributes' do
    with_session(messages: { messages: [{ id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'Hello' }], ts: 1_700_000_000_000 }] }) do |session1|
      with_session(
        name: 'session-2',
        messages: { messages: [{ id: 'msg-2', role: 'assistant', content: [{ type: 'text', text: 'Hi' }], ts: 1_700_000_000_001 }] }
      ) do |session2|
        expect(session1).not_to eq session2
        expect(session1.messages).not_to eq session2.messages
      end
    end
  end

  it 'returns false when 2 sessions have different messages attributes that are unknown' do
    with_session(
      messages: {
        messages: [
          { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'Hello' }], ts: 1_700_000_000_000, unknown_attribute: 1 }
        ]
      }
    ) do |session1|
      with_session(
        name: 'session-2',
        messages: {
          messages: [
            { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'Hello' }], ts: 1_700_000_000_000, unknown_attribute: 2 }
          ]
        }
      ) do |session2|
        expect(session1).not_to eq session2
        expect(session1.messages).not_to eq session2.messages
      end
    end
  end
end
