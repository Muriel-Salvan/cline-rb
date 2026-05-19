describe Cline::Data, '#sessions' do
  it 'returns no sessions when no sessions directory exists in data directory' do
    with_data(sessions: nil) do |data|
      expect(data.sessions).to be_nil
    end
  end

  it 'initializes sessions when data is initialized with create option' do
    with_data(sessions: nil, create: true) do |data|
      expect(data.sessions).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'sessions'))).to be true
    end
  end

  it 'initializes sessions when create option is given' do
    with_data(sessions: nil) do |data|
      expect(data.sessions(create: true)).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'sessions'))).to be true
    end
  end

  it 'returns Sessions instance with correct count when sessions exist' do
    with_data(
      sessions: {
        'session-1' => {},
        'session-2' => {},
        'session-3' => {}
      }
    ) do |data|
      sessions = data.sessions
      expect(sessions.size).to eq 3
      expect(sessions['session-1']).not_to be_nil
      expect(sessions['session-2']).not_to be_nil
      expect(sessions['session-3']).not_to be_nil
      expect(sessions['session-4']).to be_nil
    end
  end
end
