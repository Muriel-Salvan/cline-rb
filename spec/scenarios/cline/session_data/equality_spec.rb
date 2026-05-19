describe Cline::SessionData, '#==' do
  it 'returns true for session data with same content' do
    data_attributes = {
      session_id: 'test-session',
      source: 'cli',
      status: 'completed'
    }
    with_session(data: data_attributes) do |session1|
      with_session(name: 'session-2', data: data_attributes) do |session2|
        data1 = session1.data
        data2 = session2.data
        expect(data1).not_to equal data2
        expect(data1).to eq data2
      end
    end
  end

  it 'returns false for session data with different content' do
    with_session(data: { session_id: 'session-1', source: 'cli', status: 'completed' }) do |session1|
      with_session(name: 'session-2', data: { session_id: 'session-2', source: 'cli', status: 'running' }) do |session2|
        expect(session1.data).not_to eq session2.data
      end
    end
  end

  it 'returns true for session data with same metadata content' do
    with_session(
      data: {
        session_id: 'session-1',
        metadata: {
          title: 'Test Session',
          total_cost: 0.001
        }
      }
    ) do |session1|
      with_session(
        name: 'session-2',
        data: {
          session_id: 'session-2',
          metadata: {
            title: 'Test Session',
            total_cost: 0.001
          }
        }
      ) do |session2|
        expect(session1.data.metadata).to eq session2.data.metadata
      end
    end
  end

  it 'returns false for session data with different metadata content' do
    with_session(
      data: {
        session_id: 'session-1',
        metadata: { title: 'Session A', total_cost: 0.001 }
      }
    ) do |session1|
      with_session(
        name: 'session-2',
        data: {
          session_id: 'session-2',
          metadata: { title: 'Session B', total_cost: 0.002 }
        }
      ) do |session2|
        expect(session1.data.metadata).not_to eq session2.data.metadata
      end
    end
  end
end
