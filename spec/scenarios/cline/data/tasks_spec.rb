require 'fileutils'

describe Cline::Data, '#tasks' do
  it 'returns no tasks when no tasks directory exists in data directory' do
    with_data(tasks: nil) do |data|
      expect(data.tasks).to be_nil
    end
  end

  it 'returns Tasks instance with correct count when tasks exist' do
    with_data(
      tasks: {
        'task-1' => {},
        'task-2' => {},
        'task-3' => {}
      }
    ) do |data|
      tasks = data.tasks
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
    # @param cline_models [Hash{String => Hash}, nil] The Cline models to create, or nil if none
    # @yield [task] Block called with the test task ready
    # @yieldparam [Cline::Task] The test task
    def with_task(name: 'test-task', messages: nil, cline_models: nil)
      with_data(
        tasks: {
          name => {
            messages:
          }
        },
        cline_models:
      ) do |data|
        yield data.tasks[name]
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
        expect(message.usage).to be_nil
      end
    end

    it 'parses usage information from api_req_started messages' do
      with_task(
        messages: [
          {
            ts: 123_456,
            type: 'say',
            say: 'api_req_started',
            text: JSON.generate(
              {
                cost: 0.0025,
                tokensIn: 1000,
                tokensOut: 500,
                cacheReads: 200,
                cacheWrites: 150
              }
            ),
            model_info: {
              provider_id: 'openai',
              model_id: 'gpt-4',
              mode: 'act'
            }
          }
        ],
        cline_models: {
          'gpt-4' => { 'name' => 'GPT-4', 'contextWindow' => 128_000 }
        }
      ) do |task|
        usage = task.messages.first.usage
        expect(usage).not_to be_nil
        expect(usage.cost).to eq(0.0025)
        expect(usage.input_tokens).to eq(1000)
        expect(usage.output_tokens).to eq(500)
        expect(usage.cache_read_tokens).to eq(200)
        expect(usage.cache_write_tokens).to eq(150)
        expect(usage.context_tokens).to eq(1850)
        expect(usage.context_tokens_limit).to eq(128_000)
      end
    end

    it 'uses proper model with different context token limits from other data directory' do
      messages = [
        {
          type: 'say',
          say: 'api_req_started',
          text: JSON.generate({ tokensIn: 1000, tokensOut: 500 }),
          model_info: { model_id: 'test/model' }
        }
      ]
      with_task(
        messages: messages,
        cline_models: { 'test/model' => { 'name' => 'Test Model', 'contextWindow' => 128_000 } }
      ) do |task1|
        with_task(
          name: 'other-task',
          messages: messages,
          cline_models: { 'test/model' => { 'name' => 'Test Model', 'contextWindow' => 256_000 } }
        ) do |task2|
          expect(task1.messages.first.usage.context_tokens_limit).to eq(128_000)
          expect(task2.messages.first.usage.context_tokens_limit).to eq(256_000)
        end
      end
    end

    it 'handles unknown model_id gracefully' do
      with_task(
        messages: [
          {
            type: 'say',
            say: 'api_req_started',
            text: JSON.generate(
              {
                cost: 0.001,
                tokensIn: 500,
                tokensOut: 200
              }
            ),
            model_info: {
              provider_id: 'test',
              model_id: 'unknown/model',
              mode: 'act'
            }
          }
        ],
        cline_models: { 'known/model' => { 'name' => 'Known Model' } }
      ) do |task|
        usage = task.messages.first.usage
        expect(usage).not_to be_nil
        expect(usage.cost).to eq(0.001)
        expect(usage.input_tokens).to eq(500)
        expect(usage.output_tokens).to eq(200)
        expect(usage.context_tokens_limit).to be_nil
        expect(usage.cline_model).to be_nil
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

      it 'returns true for messages with same content even with different cline_models instances' do
        message_hash = {
          ts: 123_456,
          type: 'say',
          say: 'text',
          text: 'Hello world',
          model_info: {
            provider_id: 'test',
            model_id: 'test/model',
            mode: 'act'
          }
        }
        with_task(
          messages: [message_hash],
          cline_models: { 'test/model' => { 'name' => 'Test Model 1', 'contextWindow' => 128_000 } }
        ) do |task1|
          with_task(
            name: 'other-task',
            messages: [message_hash],
            cline_models: { 'test/model' => { 'name' => 'Test Model 2', 'contextWindow' => 256_000 } }
          ) do |task2|
            message1 = task1.messages.first
            message2 = task2.messages.first
            expect(message1.cline_models).not_to equal(message2.cline_models)
            expect(message1).to eq(message2)
          end
        end
      end
    end

    describe '#monitor_messages' do
      # Helper to write messages to task directory
      #
      # @param task [Cline::Task] Task to write messages for
      # @param messages [Array<Hash>, nil] Messages to write
      def write_messages(task, messages)
        json_file = File.join(task.instance_variable_get(:@task_dir), 'ui_messages.json')
        if messages
          File.write(json_file, messages.to_json)
        else
          FileUtils.rm_f(json_file)
        end
        # Wait for monitoring thread to pick up change
        sleep 0.1
      end

      # @return [Array<Hash{Symbol => Object}>] List of calls that have been made on on_message
      attr_reader :calls

      # Helper to capture messages from a task's monitoring messages.
      # on_message calls are captured in the @calls variable
      #
      # @param task [Task] The task for which we monitor the messages
      # @param ignore_partials [Boolean] Should we ignore partial messages?
      # @yield Optional code called with monitoring in place
      def capture_on_message(task, ignore_partials: false)
        @calls = []
        task.monitor_messages(
          on_message: proc do |message, last, previous_version|
            calls << {
              message: message,
              last: last,
              previous_version: previous_version
            }
          end,
          monitoring_interval_secs: 0.01,
          ignore_partials:
        ) do
          # Wait for the monitoring thread to have started
          sleep 0.05
          yield if block_given?
          # Wait for the monitoring thread to eventually catch-up on updates
          sleep 0.05
        end
      end

      it 'calls on_message for each message even without modifications' do
        with_task(
          messages: [
            { ts: 100, type: 'user', text: 'First message' },
            { ts: 101, type: 'assistant', text: 'Response' }
          ]
        ) do |task|
          capture_on_message(task)
          expect(calls.size).to eq 2
          expect(calls[0][:message].ts).to eq 100
          expect(calls[0][:last]).to be false
          expect(calls[0][:previous_version]).to be_nil
          expect(calls[1][:message].ts).to eq 101
          expect(calls[1][:last]).to be true
          expect(calls[1][:previous_version]).to be_nil
        end
      end

      it 'calls on_message when file is created after monitoring starts' do
        with_task(messages: nil) do |task|
          capture_on_message(task) do
            # Now create the messages file
            write_messages(
              task,
              [
                { ts: 100, type: 'user', text: 'Message after create' }
              ]
            )
          end
          expect(calls.size).to eq 1
          expect(calls[0][:message].ts).to eq 100
          expect(calls[0][:last]).to be true
          expect(calls[0][:previous_version]).to be_nil
        end
      end

      it 'calls on_message only for new messages when adding new messages' do
        with_task(
          messages: [
            { ts: 100, type: 'user', text: 'First message' },
            { ts: 101, type: 'assistant', text: 'Response' }
          ]
        ) do |task|
          capture_on_message(task) do
            calls.clear
            # Add new messages
            write_messages(
              task,
              [
                { ts: 100, type: 'user', text: 'First message' },
                { ts: 101, type: 'assistant', text: 'Response' },
                { ts: 102, type: 'user', text: 'Second question' },
                { ts: 103, type: 'assistant', text: 'Second response' }
              ]
            )
          end
          # Only new messages should be called
          expect(calls.size).to eq 2
          expect(calls[0][:message].ts).to eq 102
          expect(calls[0][:last]).to be false
          expect(calls[0][:previous_version]).to be_nil
          expect(calls[1][:message].ts).to eq 103
          expect(calls[1][:last]).to be true
          expect(calls[1][:previous_version]).to be_nil
        end
      end

      it 'calls on_message only for updated messages when modifying existing messages in the middle' do
        with_task(
          messages: [
            { ts: 100, type: 'user', text: 'First message' },
            { ts: 101, type: 'assistant', text: 'Original response' },
            { ts: 102, type: 'user', text: 'Second message' }
          ]
        ) do |task|
          original_message = nil
          capture_on_message(task) do
            # Save original message for previous_version check
            original_message = task.messages[1]
            calls.clear
            # Modify only the middle message
            write_messages(
              task, [
                { ts: 100, type: 'user', text: 'First message' },
                { ts: 101, type: 'assistant', text: 'Updated response' },
                { ts: 102, type: 'user', text: 'Second message' }
              ]
            )
          end
          expect(calls.size).to eq 1
          expect(calls[0][:message].ts).to eq 101
          expect(calls[0][:message].text).to eq 'Updated response'
          expect(calls[0][:last]).to be false
          expect(calls[0][:previous_version]).to eq original_message
        end
      end

      it 'ignores partial messages when ignore_partials is true' do
        with_task(
          messages: [
            { ts: 100, type: 'user', text: 'Normal message', partial: false },
            { ts: 101, type: 'assistant', text: 'Partial message', partial: true },
            { ts: 102, type: 'user', text: 'Another normal', partial: false }
          ]
        ) do |task|
          capture_on_message(task, ignore_partials: true)
          expect(calls.size).to eq 2
          expect(calls[0][:message].ts).to eq 100
          expect(calls[1][:message].ts).to eq 102
        end
      end

      it 'updates task.messages accessor with new content when messages are monitored' do
        with_task(
          messages: [
            { ts: 100, type: 'user', text: 'First message' }
          ]
        ) do |task|
          expect(task.messages.size).to eq 1
          capture_on_message(task) do
            write_messages(
              task, [
                { ts: 100, type: 'user', text: 'First message' },
                { ts: 101, type: 'assistant', text: 'New message' }
              ]
            )
          end
          expect(task.messages.size).to eq 2
          expect(task.messages[1].ts).to eq 101
          expect(task.messages[1].text).to eq 'New message'
        end
      end

      it 'returns monitor object when no block given and stops monitoring after #stop is called' do
        with_task(messages: nil) do |task|
          @calls = []
          monitor = task.monitor_messages(
            on_message: proc do |message, last, previous_version|
              calls << {
                message: message,
                last: last,
                previous_version: previous_version
              }
            end,
            monitoring_interval_secs: 0.01
          )
          # Wait for monitoring thread to start
          sleep 0.05
          # First write should trigger on_message call
          write_messages(task, [{ ts: 100, type: 'user', text: 'First message' }])
          sleep 0.05
          expect(calls.size).to eq 1
          calls.clear
          # Stop the monitor
          monitor.stop
          # Second write should NOT trigger on_message call after stop
          write_messages(
            task,
            [
              { ts: 100, type: 'user', text: 'First message' },
              { ts: 101, type: 'user', text: 'Second message' }
            ]
          )
          sleep 0.05
          expect(calls).to be_empty
        end
      end
    end
  end
end
