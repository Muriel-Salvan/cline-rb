describe Cline::Task, '#messages' do
  it 'returns nil when no messages.json file exists in task directory' do
    with_task(messages: nil) do |task|
      expect(task.messages).to be_nil
    end
  end

  it 'initializes messages when task is initialized with create option' do
    with_task(messages: nil, create: true) do |task|
      messages = task.messages
      expect(messages).not_to be_nil
      expect(messages).to be_empty
      expect(File.exist?(File.join(task.dir, 'ui_messages.json'))).to be true
    end
  end

  it 'initializes messages when create option is given' do
    with_task(messages: nil) do |task|
      messages = task.messages(create: true)
      expect(messages).not_to be_nil
      expect(messages).to be_empty
      expect(File.exist?(File.join(task.dir, 'ui_messages.json'))).to be true
    end
  end

  it 'reads all attributes of the messages' do
    with_task(
      messages: [
        {
          ts: 123_456,
          type: 'assistant',
          say: 'execution_start',
          ask: 'approval',
          text: 'This is a test message',
          modelInfo: {
            providerId: 'openai',
            modelId: 'gpt-4',
            mode: 'act'
          },
          conversationHistoryIndex: 5,
          partial: false
        }
      ]
    ) do |task|
      messages = task.messages
      expect(messages.size).to eq 1
      message = messages.first
      expect(message.ts).to eq 123_456
      expect(message.timestamp).to eq Time.at(123.456)
      expect(message.type).to eq 'assistant'
      expect(message.say).to eq 'execution_start'
      expect(message.ask).to eq 'approval'
      expect(message.text).to eq 'This is a test message'
      expect(message.model_info).not_to be_nil
      expect(message.model_info.provider_id).to eq 'openai'
      expect(message.model_info.model_id).to eq 'gpt-4'
      expect(message.model_info.mode).to eq 'act'
      expect(message.conversation_history_index).to eq 5
      expect(message.partial).to be false
      expect(message.usage).to be_nil
    end
  end

  it 'ignores extra unknown parameters from messages.json file' do
    with_task(
      messages: [
        { ts: 123_456, type: 'user', text: 'Hello', this_is_an_unknown_parameter: 'should be ignored' },
        { ts: 123_457, type: 'assistant', text: 'Hi there', another_extra_field: 12_345 }
      ]
    ) do |task|
      messages = task.messages
      # Verify valid attributes are still correctly loaded
      expect(messages.size).to eq 2
      expect(messages.first.ts).to eq 123_456
      expect(messages.first.type).to eq 'user'
      expect(messages.first.text).to eq 'Hello'
      # Verify unknown parameters are not present on the object
      expect(messages.first).not_to respond_to(:this_is_an_unknown_parameter)
      expect(messages.first).not_to respond_to(:thisIsAnUnknownParameter)
      expect(messages[1]).not_to respond_to(:another_extra_field)
      expect(messages[1]).not_to respond_to(:anotherExtraField)
    end
  end

  it 'loads all messages' do
    with_task(
      messages: [
        { ts: 100, type: 'user', text: 'First message' },
        { ts: 101, type: 'assistant', text: 'Response 1' },
        { ts: 102, type: 'user', text: 'Second question' },
        { ts: 103, type: 'assistant', text: 'Response 2' }
      ]
    ) do |task|
      messages = task.messages
      expect(messages.size).to eq 4
      expect(messages[0].ts).to eq 100
      expect(messages[1].ts).to eq 101
      expect(messages[2].ts).to eq 102
      expect(messages[3].ts).to eq 103
    end
  end

  describe '#save' do
    it 'persists modified messages to the ui_messages.json file' do
      with_task(
        messages: [
          { ts: 100, type: 'user', text: 'Hello', unknownAttribute: 'Unknown value' },
          { ts: 101, type: 'assistant', text: 'Hi there' }
        ]
      ) do |task|
        messages = task.messages
        messages.first.text = 'Updated hello'
        messages << {
          ts: 102,
          type: 'say',
          say: 'text',
          text: 'Another question'
        }
        messages.save
        file_content = JSON.parse(File.read(File.join(task.dir, 'ui_messages.json')))
        expect(file_content.size).to eq 3
        expect(file_content[0]['ts']).to eq 100
        expect(file_content[0]['type']).to eq 'user'
        expect(file_content[0]['text']).to eq 'Updated hello'
        expect(file_content[0]['unknownAttribute']).to eq 'Unknown value'
        expect(file_content[1]['ts']).to eq 101
        expect(file_content[1]['type']).to eq 'assistant'
        expect(file_content[1]['text']).to eq 'Hi there'
        expect(file_content[2]['ts']).to eq 102
        expect(file_content[2]['type']).to eq 'say'
        expect(file_content[2]['say']).to eq 'text'
        expect(file_content[2]['text']).to eq 'Another question'
      end
    end

    it 'persists a newly instantiated ui_messages file' do
      with_task(messages: nil) do |task|
        messages = task.messages(create: true)
        messages << {
          ts: 100,
          type: 'say',
          say: 'text',
          text: 'Hello'
        }
        messages.save
        expect(JSON.parse(File.read(File.join(task.dir, 'ui_messages.json')), symbolize_names: true)).to eq(
          [
            {
              ts: 100,
              type: 'say',
              say: 'text',
              text: 'Hello'
            }
          ]
        )
      end
    end
  end

  it 'raises Errno::EACCES after retrying 3 times when the file cannot be read' do
    with_task(
      messages: [
        { ts: 100, type: 'user', text: 'First message' }
      ]
    ) do |task|
      read_call_count = 0
      allow(File).to receive(:read).with(File.join(task.dir, Cline::TaskMessages.cline_json_file_def)) do |*_args|
        read_call_count += 1
        raise Errno::EACCES
      end
      expect { task.messages }.to raise_error(Errno::EACCES)
      expect(read_call_count).to eq 4
    end
  end

  it 'recovers from a temporary read error and reads the file successfully on retry' do
    with_task(
      messages: [
        { ts: 100, type: 'user', text: 'First message' }
      ]
    ) do |task|
      read_call_count = 0
      original_read = File.method(:read)
      allow(File).to receive(:read).with(File.join(task.dir, Cline::TaskMessages.cline_json_file_def)) do |*args|
        read_call_count += 1
        raise Errno::EACCES if read_call_count == 1

        original_read.call(*args)
      end

      messages = task.messages
      expect(read_call_count).to eq 2
      expect(messages).not_to be_nil
      expect(messages.size).to eq 1
      expect(messages.first.ts).to eq 100
    end
  end

  it 'raises JSON::ParserError after retrying 3 times when the file contains invalid JSON' do
    with_task(
      messages: [
        { ts: 100, type: 'user', text: 'First message' }
      ]
    ) do |task|
      read_call_count = 0
      allow(File).to receive(:read).with(File.join(task.dir, Cline::TaskMessages.cline_json_file_def)) do |*_args|
        read_call_count += 1
        '{invalid json content'
      end
      expect { task.messages }.to raise_error(JSON::ParserError)
      expect(read_call_count).to eq 4
    end
  end

  it 'recovers from invalid JSON and parses the file successfully on retry' do
    with_task(
      messages: [
        { ts: 100, type: 'user', text: 'First message' }
      ]
    ) do |task|
      read_call_count = 0
      original_read = File.method(:read)
      allow(File).to receive(:read).with(File.join(task.dir, Cline::TaskMessages.cline_json_file_def)) do |*args|
        read_call_count += 1
        if read_call_count == 1
          '{invalid json content'
        else
          original_read.call(*args)
        end
      end

      messages = task.messages
      expect(read_call_count).to eq 2
      expect(messages).not_to be_nil
      expect(messages.size).to eq 1
      expect(messages.first.ts).to eq 100
    end
  end
end
