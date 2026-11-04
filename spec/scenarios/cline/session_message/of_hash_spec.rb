describe Cline::SessionMessage, '.of_hash' do
  # Read the first message of a session initialized from the given message content.
  #
  # @param content [Array<Hash{Symbol => Object}>] The content blocks of the message to create
  # @return [Cline::SessionMessage] The corresponding deserialized message
  def first_message_with(content)
    message = nil
    with_session(
      messages: {
        messages: [
          { id: 'msg-1', role: 'assistant', ts: 100, content: }
        ]
      }
    ) do |session|
      message = session.messages.first
    end
    message
  end

  it 'deserializes a valid tool use input' do
    message = first_message_with(
      [
        {
          type: 'tool_use',
          id: 'tool-1',
          name: 'ask_question',
          input: {
            question: 'Continue?',
            options: %w[Yes No],
            path: '/path/to/file',
            commands: 'echo hello',
            old_text: nil,
            files: [{ path: '/path/to/file1' }],
            unknown_attribute: 'ignored'
          }
        }
      ]
    )

    input = message.content[0].input
    expect(input.question).to eq 'Continue?'
    expect(input.options.to_a).to eq %w[Yes No]
    expect(input.path).to eq '/path/to/file'
    expect(input.commands).to eq 'echo hello'
    expect(input.old_text).to be_nil
    expect(input.files[0].path).to eq '/path/to/file1'
    expect(input.extra_attributes).to eq('unknown_attribute' => 'ignored')
    expect(input.wrong_attributes).to be_nil
  end

  it 'does not raise and stores the raw value when a tool use input attribute has a wrong type' do
    message = first_message_with(
      [
        {
          type: 'tool_use',
          id: 'tool-1',
          name: 'read_files',
          input: { question: 'Continue?', files: ['not-a-file'] }
        }
      ]
    )

    input = message.content[0].input
    expect(message.id).to eq 'msg-1'
    expect(message.role).to eq 'assistant'
    expect(message.content[0].type).to eq 'tool_use'
    expect(message.content[0].name).to eq 'read_files'
    expect(input.question).to eq 'Continue?'
    expect(input.wrong_attributes).to eq(files: ['not-a-file'])
  end

  it 'does not raise and stores the raw value when a nested file input attribute has a wrong type' do
    message = first_message_with(
      [
        {
          type: 'tool_use',
          id: 'tool-1',
          name: 'read_files',
          input: { files: [{ path: ['/not', 'a', 'string'] }] }
        }
      ]
    )

    input = message.content[0].input
    expect(message.content[0].type).to eq 'tool_use'
    expect(message.content[0].name).to eq 'read_files'
    expect(input.files).to be_nil
    expect(input.wrong_attributes).to eq(files: [{ 'path' => ['/not', 'a', 'string'] }])
  end

  it 'does not raise when the tool use input is not a Hash' do
    message = first_message_with(
      [
        { type: 'tool_use', id: 'tool-1', name: 'read_files', input: 'garbage' }
      ]
    )

    expect(message.content[0].type).to eq 'tool_use'
    expect(message.content[0].name).to eq 'read_files'
    expect(message.content[0].input.wrong_attributes).to eq('_raw' => 'garbage')
  end

  it 'deserializes a tool result content given as a String' do
    message = first_message_with(
      [
        { type: 'tool_result', tool_use_id: 'tool-1', content: 'File content here' }
      ]
    )

    tool_result = message.content[0]
    expect(tool_result.type).to eq 'tool_result'
    expect(tool_result.tool_use_id).to eq 'tool-1'
    expect(tool_result.content).to eq 'File content here'
  end

  it 'deserializes a tool result content given as a list of entries' do
    message = first_message_with(
      [
        {
          type: 'tool_result',
          tool_use_id: 'tool-1',
          content: [
            { query: 'cd /path && ls', result: 'file.txt', success: true, unknown_attribute: 'kept' }
          ]
        }
      ]
    )

    tool_result = message.content[0]
    expect(tool_result.type).to eq 'tool_result'
    expect(tool_result.tool_use_id).to eq 'tool-1'
    expect(tool_result.content.size).to eq 1
    expect(tool_result.content[0].query).to eq 'cd /path && ls'
    expect(tool_result.content[0].result).to eq 'file.txt'
    expect(tool_result.content[0].success).to be true
    expect(tool_result.content[0].extra_attributes).to eq('unknown_attribute' => 'kept')
  end
end
