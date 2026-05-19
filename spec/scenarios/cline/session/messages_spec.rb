describe Cline::Session, '#messages' do
  it 'returns nil when no messages.json file exists in session directory' do
    with_session(messages: nil) do |session|
      expect(session.messages).to be_nil
    end
  end

  it 'initializes messages when session is initialized with create option' do
    with_session(messages: nil, create: true) do |session|
      messages = session.messages
      expect(messages).not_to be_nil
      expect(messages).to be_empty
      expect(File.exist?(File.join(session.dir, 'test-session.messages.json'))).to be true
    end
  end

  it 'initializes messages when create option is given' do
    with_session(messages: nil) do |session|
      messages = session.messages(create: true)
      expect(messages).not_to be_nil
      expect(messages).to be_empty
      expect(File.exist?(File.join(session.dir, 'test-session.messages.json'))).to be true
    end
  end

  it 'reads all attributes of the messages' do
    with_session(
      # TODO: Add attributes other than the messages Array
      messages: [
        {
          id: 'msg-1',
          role: 'assistant',
          content: [
            {
              type: 'text',
              text: 'Hello world'
            }
          ],
          ts: 123_456_789,
          modelInfo: {
            id: 'deepseek/deepseek-v4-flash',
            provider: 'deepseek',
            family: 'deepseek-v4'
          },
          metrics: {
            inputTokens: 1000,
            outputTokens: 500,
            cacheReadTokens: 200,
            cacheWriteTokens: 150,
            cost: 0.0025
          }
        }
      ]
    ) do |session|
      messages = session.messages
      expect(messages.size).to eq 1
      message = messages.first
      expect(message.id).to eq 'msg-1'
      expect(message.role).to eq 'assistant'
      expect(message.ts).to eq 123_456_789
      expect(message.timestamp).to eq Time.at(123_456.789)
      expect(message.model_info).not_to be_nil
      expect(message.model_info.id).to eq 'deepseek/deepseek-v4-flash'
      expect(message.model_info.provider).to eq 'deepseek'
      expect(message.model_info.family).to eq 'deepseek-v4'
      expect(message.metrics).not_to be_nil
      expect(message.metrics.input_tokens).to eq 1000
      expect(message.metrics.output_tokens).to eq 500
      expect(message.metrics.cache_read_tokens).to eq 200
      expect(message.metrics.cache_write_tokens).to eq 150
      expect(message.metrics.cost).to eq 0.0025
      # TODO: Add expectations on all missing attributes
    end
  end

  it 'reads message content blocks' do
    with_session(
      messages: [
        {
          id: 'msg-1',
          role: 'user',
          content: [
            { type: 'text', text: 'Hello' },
            { type: 'tool_use', id: 'tool-1', name: 'read_file', input: { question: 'Which file?', options: %w[file1 file2] } },
            { type: 'tool_result', tool_use_id: 'tool-1', content: 'File content here' }
          ],
          ts: 100
        }
      ]
    ) do |session|
      messages = session.messages
      expect(messages.size).to(eq(1))
      content = messages.first.content
      expect(content.size).to(eq(3))
      expect(content[0].type).to eq 'text'
      expect(content[0].text).to eq 'Hello'
      expect(content[1].type).to eq 'tool_use'
      expect(content[1].id).to eq 'tool-1'
      expect(content[1].name).to eq 'read_file'
      expect(content[1].input).not_to be_nil
      expect(content[1].input.question).to eq 'Which file?'
      expect(content[1].input.options).to eq %w[file1 file2]
      expect(content[2].type).to eq 'tool_result'
      expect(content[2].tool_use_id).to eq 'tool-1'
      expect(content[2].content).to eq 'File content here'
    end
  end

  it 'ignores extra unknown parameters from messages.json file' do
    with_session(
      # TODO: Add also unknown parameter in the root attributes of this file
      messages: [
        { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'Hello' }], ts: 123, this_is_an_unknown_parameter: 'should be ignored' },
        { id: 'msg-2', role: 'assistant', content: [{ type: 'text', text: 'Hi there' }], ts: 124, another_extra_field: 12_345 }
      ]
    ) do |session|
      messages = session.messages
      # Verify valid attributes are still correctly loaded
      expect(messages.size).to eq 2
      expect(messages.first.id).to eq 'msg-1'
      expect(messages.first.role).to eq 'user'
      # Verify unknown parameters are not present on the object
      expect(messages.first).not_to respond_to(:this_is_an_unknown_parameter)
      expect(messages.first).not_to respond_to(:thisIsAnUnknownParameter)
      expect(messages[1]).not_to respond_to(:another_extra_field)
      expect(messages[1]).not_to respond_to(:anotherExtraField)
    end
  end

  it 'loads all messages' do
    with_session(
      messages: [
        { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'First message' }], ts: 100 },
        { id: 'msg-2', role: 'assistant', content: [{ type: 'text', text: 'Response 1' }], ts: 101 },
        { id: 'msg-3', role: 'user', content: [{ type: 'text', text: 'Second question' }], ts: 102 },
        { id: 'msg-4', role: 'assistant', content: [{ type: 'text', text: 'Response 2' }], ts: 103 }
      ]
    ) do |session|
      messages = session.messages
      expect(messages.size).to eq 4
      expect(messages[0].ts).to eq 100
      expect(messages[1].ts).to eq 101
      expect(messages[2].ts).to eq 102
      expect(messages[3].ts).to eq 103
    end
  end

  describe '#save' do
    it 'persists modified messages to the messages.json file' do
      with_session(
        messages: [
          { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'Hello' }], ts: 100, unknownAttribute: 'Unknown value' },
          { id: 'msg-2', role: 'assistant', content: [{ type: 'text', text: 'Hi there' }], ts: 101 }
        ]
      ) do |session|
        messages = session.messages
        messages[0].content << Cline::SessionMessage::MessageContent.new(type: 'text', text: 'Updated content')
        messages[0].content[0].text = 'World'
        messages << Cline::SessionMessage.new(
          id: 'msg-3',
          role: 'user',
          content: [Cline::SessionMessage::MessageContent.new(type: 'text', text: 'Another question')],
          ts: 102
        )
        messages.save
        expect(JSON.parse(File.read(File.join(session.dir, 'test-session.messages.json')))).to eq(
          {
            'messages' => [
              {
                'id' => 'msg-1',
                'role' => 'user',
                'content' => [
                  { 'type' => 'text', 'text' => 'World' },
                  { 'type' => 'text', 'text' => 'Updated content' }
                ],
                'ts' => 100,
                'unknownAttribute' => 'Unknown value'
              },
              {
                'id' => 'msg-2',
                'role' => 'assistant',
                'content' => [
                  { 'type' => 'text', 'text' => 'Hi there' }
                ],
                'ts' => 101
              },
              {
                'id' => 'msg-3',
                'role' => 'user',
                'content' => [
                  { 'type' => 'text', 'text' => 'Another question' }
                ],
                'ts' => 102
              }
            ]
          }
        )
      end
    end

    it 'persists a newly instantiated messages file' do
      with_session(messages: nil) do |session|
        messages = session.messages(create: true)
        messages << Cline::SessionMessage.new(
          id: 'msg-1',
          role: 'user',
          content: [Cline::SessionMessage::MessageContent.new(type: 'text', text: 'Hello')],
          ts: 100
        )
        messages.save
        expect(JSON.parse(File.read(File.join(session.dir, 'test-session.messages.json')))).to eq(
          {
            'messages' => [
              {
                'id' => 'msg-1',
                'role' => 'user',
                'content' => [
                  { 'type' => 'text', 'text' => 'Hello' }
                ],
                'ts' => 100
              }
            ]
          }
        )
      end
    end
  end

  it 'raises Errno::EACCES after retrying 3 times when the file cannot be read' do
    with_session(
      messages: [
        { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'First message' }], ts: 100 }
      ]
    ) do |session|
      read_call_count = 0
      allow(File).to(receive(:read).with(File.join(session.dir, 'test-session.messages.json'))) do |*_args|
        read_call_count += 1
        raise Errno::EACCES
      end
      expect { session.messages }.to raise_error(Errno::EACCES)
      expect(read_call_count).to eq 4
    end
  end

  it 'recovers from a temporary read error and reads the file successfully on retry' do
    with_session(
      messages: [
        { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'First message' }], ts: 100 }
      ]
    ) do |session|
      read_call_count = 0
      original_read = File.method(:read)
      allow(File).to(receive(:read).with(File.join(session.dir, 'test-session.messages.json'))) do |*args|
        read_call_count += 1
        raise Errno::EACCES if read_call_count == 1

        original_read.call(*args)
      end

      messages = session.messages
      expect(read_call_count).to eq 2
      expect(messages).not_to be_nil
      expect(messages.size).to eq 1
      expect(messages.first.ts).to eq 100
    end
  end
end
