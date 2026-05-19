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

  # TODO: Repeat also those 3 tests for messages, not just data
end
