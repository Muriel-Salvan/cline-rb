describe Cline::Sessions, '#new' do
  it 'creates a new session and its directory from scratch' do
    with_data(sessions: {}) do |data|
      sessions = data.sessions
      session = sessions.new('my-session')
      expect(File.directory?(File.join(sessions.dir, 'my-session'))).to be true
      expect(sessions['my-session']).to eq session
    end
  end

  it 'uses existing session content when called with an existing sub-directory name' do
    with_data(
      sessions: {
        'my-session' => {
          data: {
            session_id: 'my-session',
            source: 'cli',
            status: 'completed'
          },
          messages: {
            messages: [
              { ts: 123_456, role: 'user', content: [{ type: 'text', text: 'Hello' }] }
            ]
          }
        }
      },
      create: true
    ) do |data|
      sessions = data.sessions
      session = sessions.new('my-session')
      expect(sessions['my-session'].data.session_id).to eq 'my-session'
      expect(session.data.session_id).to eq 'my-session'
    end
  end

  it 'creates child data objects when accessed on a newly created session' do
    with_data(sessions: {}) do |data|
      sessions = data.sessions
      session = sessions.new('my-session')
      # Check that children data has not been created yet
      expect(File.exist?(File.join(session.dir, 'my-session.json'))).to be false
      session_data = session.data
      expect(File.exist?(File.join(session.dir, 'my-session.json'))).to be true
      expect(session_data).not_to be_nil
    end
  end
end
