describe Cline::SessionMessages, '#cast' do
  # @return [Cline::SessionMessages] A session messages instance to be tested
  attr_reader :session_messages

  around do |example|
    with_session(
      name: 'test-session',
      messages: { messages: [] },
      create: true
    ) do |session|
      @session_messages = session.messages
      example.run
    end
  end

  it 'initializes messages collection from Array of Hashes' do
    session_messages.messages = [
      { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'Hello' }], ts: 100 },
      { id: 'msg-2', role: 'assistant', content: [{ type: 'text', text: 'Hi there' }], ts: 200 }
    ]
    expect(session_messages.messages.size).to eq 2
    expect(session_messages.messages[0].id).to eq 'msg-1'
    expect(session_messages.messages[0].role).to eq 'user'
    expect(session_messages.messages[0].content[0].text).to eq 'Hello'
    expect(session_messages.messages[1].id).to eq 'msg-2'
    expect(session_messages.messages[1].role).to eq 'assistant'
    expect(session_messages.messages[1].content[0].text).to eq 'Hi there'
  end
end
