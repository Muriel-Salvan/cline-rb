describe Cline::Data, '#tasks' do
  it 'returns no tasks when no tasks directory exists in data directory' do
    with_data_dir(tasks: nil) do |data_dir|
      expect(described_class.from_dir(data_dir).tasks).to be_nil
    end
  end

  it 'returns Tasks instance with correct count when tasks exist' do
    with_data_dir(
      tasks: {
        'task-1' => {},
        'task-2' => {},
        'task-3' => {}
      }
    ) do |data_dir|
      tasks = described_class.from_dir(data_dir).tasks
      expect(tasks.size).to eq 3
      expect(tasks['task-1']).not_to be_nil
      expect(tasks['task-2']).not_to be_nil
      expect(tasks['task-3']).not_to be_nil
      expect(tasks['task-4']).to be_nil
    end
  end

  describe '#messages' do
    # Provide a test task
    #
    # @param name [String] The task name
    # @param messages [Array<Hash>, nil] The task messages, or nil if none
    # @yield [task] Block called with the test task ready
    # @yieldparam [Cline::Task] The test task
    def with_task(name: 'test-task', messages: nil)
      with_data_dir(
        tasks: {
          name => {
            messages:
          }
        }
      ) do |data_dir|
        yield described_class.from_dir(data_dir).tasks[name]
      end
    end

    it 'returns nil when no messages.json file exists in task directory' do
      with_task(messages: nil) do |task|
        expect(task.messages).to be_nil
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
            model_info: {
              provider_id: 'openai',
              model_id: 'gpt-4',
              mode: 'act'
            },
            conversation_history_index: 5,
            partial: false
          }
        ]
      ) do |task|
        messages = task.messages
        expect(messages.size).to eq 1
        message = messages.first
        expect(message.ts).to eq 123_456
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
        expect(messages[1]).not_to respond_to(:another_extra_field)
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

    describe '#==' do
      it 'returns true when 2 tasks from different data directories have the same messages' do
        messages_array = [
          { ts: 12_345, type: 'user', text: 'Hello' },
          { ts: 12_346, type: 'assistant', text: 'Hi' }
        ]

        with_task(messages: messages_array) do |task1|
          with_task(name: 'test-task-2', messages: messages_array) do |task2|
            # Tasks are from different data directories but have identical messages
            expect(task1).not_to equal(task2) # Different instances
            expect(task1).to eq(task2)
            expect(task1.messages).not_to equal(task2.messages)
            expect(task1.messages).to eq(task2.messages)
          end
        end
      end

      it 'returns false when 2 tasks have different message attributes' do
        with_task(messages: [{ ts: 123, type: 'user', text: 'Hello' }]) do |task1|
          with_task(messages: [{ ts: 123, type: 'user', text: 'Different' }]) do |task2|
            expect(task1).not_to eq(task2)
            expect(task1.messages).not_to eq(task2.messages)
          end
        end
      end

      it 'returns false when 2 tasks have different message attributes that are unknown' do
        with_task(messages: [{ ts: 123, type: 'user', text: 'Hello', unknown_attribute: 1 }]) do |task1|
          with_task(messages: [{ ts: 123, type: 'user', text: 'Hello', unknown_attribute: 2 }]) do |task2|
            expect(task1).not_to eq(task2)
            expect(task1.messages).not_to eq(task2.messages)
          end
        end
      end
    end
  end
end
