describe Cline::SessionMessage, '#to_human' do
  # Create a session with a message, and provide the corresponding human message for expectations.
  #
  # @param limit [Integer] Limit to call to_human with
  # @param kwargs [Hash{Symbol => Object}] Additional JSON message fields
  # @return [String] The corresponding human message
  def human_message(limit: 128, **kwargs)
    result = nil
    with_session(messages: { messages: [{ id: 'msg-1', content: [{ type: 'text', text: 'Hello' }], ts: 123_456, **kwargs }] }) do |session|
      result = session.messages.first.to_human(limit:)
    end
    result
  end

  it 'converts user message to human format' do
    expect(
      human_message(role: 'user', content: [{ type: 'text', text: 'Hello' }])
    ).to eq 'User: Hello'
  end

  it 'converts assistant message to human format' do
    expect(
      human_message(role: 'assistant', content: [{ type: 'text', text: 'Hello' }])
    ).to eq 'Assistant: Hello'
  end

  it 'respects character limit parameter' do
    expect(
      human_message(
        limit: 50,
        id: 'msg-1',
        role: 'user',
        content: [{ type: 'text', text: 'a' * 200 }],
        ts: 123_456
      ).length
    ).to be <= 50
  end

  it 'handles multi-line content correctly' do
    expect(
      human_message(
        id: 'msg-1',
        role: 'user',
        content: [{ type: 'text', text: "Line 1\nLine 2\nLine 3" }],
        ts: 100
      )
    ).to eq 'User: Line 1 Line 2 Line 3'
  end

  it 'returns human description for messages with tool_use content' do
    expect(
      human_message(
        id: 'msg-1',
        role: 'assistant',
        content: [
          { type: 'tool_use', id: 'tool-1', name: 'read_file', input: { question: 'Which file?' } }
        ],
        ts: 100
      )
    ).to eq 'Assistant uses read_file'
  end

  it 'returns human description for messages with tool_result content' do
    expect(
      human_message(
        id: 'msg-1',
        role: 'tool',
        content: [
          { type: 'tool_result', toolUseId: 'tool-1', content: 'File content here' }
        ],
        ts: 100
      )
    ).to eq 'Tool result: File content here'
  end

  it 'converts message with model info to human format' do
    expect(
      human_message(
        id: 'msg-1',
        role: 'assistant',
        content: [{ type: 'text', text: 'Response with model' }],
        ts: 123_456,
        modelInfo: { id: 'test/model', provider: 'test', family: 'test' }
      )
    ).to eq 'Assistant: Response with model'
  end
end
