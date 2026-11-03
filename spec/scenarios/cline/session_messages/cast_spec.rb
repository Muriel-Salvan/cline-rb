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
      { id: 'msg-2', role: 'assistant', content: [{ type: 'text', text: 'Hi there' }], ts: 200 },
      {
        id: 'msg-3',
        role: 'assistant',
        content: [
          { type: 'thinking', thinking: 'Let me think...' },
          { type: 'tool_use', id: 'tool-1', name: 'read_files', input: { files: [{ path: '/path/file.rb' }] } }
        ],
        ts: 300,
        model_info: { id: 'test/model', provider: 'test', family: 'test-family' },
        metrics: { input_tokens: 10, output_tokens: 20, cache_read_tokens: 5, cache_write_tokens: 2, cost: 0.001 }
      }
    ]
    expect(session_messages.messages.size).to eq 3
    expect(session_messages.messages[0].id).to eq 'msg-1'
    expect(session_messages.messages[0].role).to eq 'user'
    expect(session_messages.messages[0].content[0].text).to eq 'Hello'
    expect(session_messages.messages[1].id).to eq 'msg-2'
    expect(session_messages.messages[1].role).to eq 'assistant'
    expect(session_messages.messages[1].content[0].text).to eq 'Hi there'
    expect(session_messages.messages[2].content[0].type).to eq 'thinking'
    expect(session_messages.messages[2].content[0].thinking).to eq 'Let me think...'
    expect(session_messages.messages[2].content[1].type).to eq 'tool_use'
    expect(session_messages.messages[2].content[1].name).to eq 'read_files'
    expect(session_messages.messages[2].content[1].input.files.to_a.size).to eq 1
    expect(session_messages.messages[2].content[1].input.files[0].path).to eq '/path/file.rb'
    expect(session_messages.messages[2].model_info.id).to eq 'test/model'
    expect(session_messages.messages[2].model_info.provider).to eq 'test'
    expect(session_messages.messages[2].model_info.family).to eq 'test-family'
    expect(session_messages.messages[2].metrics.input_tokens).to eq 10
    expect(session_messages.messages[2].metrics.output_tokens).to eq 20
    expect(session_messages.messages[2].metrics.cache_read_tokens).to eq 5
    expect(session_messages.messages[2].metrics.cache_write_tokens).to eq 2
    expect(session_messages.messages[2].metrics.cost).to eq 0.001
  end
end
