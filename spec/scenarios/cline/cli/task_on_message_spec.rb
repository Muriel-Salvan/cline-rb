describe Cline::Cli, '#task' do
  describe 'the on_message callback' do
    # Run a Cline's task and capture all the messages received by the on_message callback
    #
    # @param mock_config [Hash{Symbol => Object}] The Cline mock configuration (see #ClineTest::Helpers::Cli#mock_commands)
    # @param monitoring_interval_secs [Float] The monitoring interval in seconds.
    # @return [Array<Hash{Symbol => Object}>] The list of messages received by the on_message callback:
    #   * message [Message] The message that was received.
    #   * last [Boolean] Is this message the last one of the discussion?
    #   * previous_version [Message, nil] Previous version of this message, or nil if it is a new one.
    def capture_messages(mock_config = {}, monitoring_interval_secs: 0.1)
      messages_received = []
      with_config_dir do |config_dir|
        mock_commands("cline --config #{config_dir}" => mock_config)
        # Create CLI instance with our test config directory
        described_class.new(config: config_dir).task(
          'Test prompt',
          on_message: proc { |message, last, previous|
            messages_received << {
              message: message,
              last: last,
              previous_version: previous
            }
          },
          monitoring_interval_secs:
        )
      end
      messages_received
    end

    it 'triggers on_message callback for messages added during task execution' do
      messages_received = capture_messages(
        {
          task: {
            messages: [
              { ts: 100, text: 'Test message 1' },
              [
                # Those 2 messages will be sent at the same time
                { ts: 101, text: 'Test response 1' },
                { ts: 102, text: 'Test message 2' }
              ],
              { ts: 103, text: 'Test message 3' }
            ]
          }
        }
      )
      expect(messages_received.size).to eq 4
      expect(messages_received[0][:message].ts).to eq 100
      expect(messages_received[0][:last]).to be true
      expect(messages_received[1][:message].ts).to eq 101
      expect(messages_received[1][:last]).to be false
      expect(messages_received[2][:message].ts).to eq 102
      expect(messages_received[2][:last]).to be true
      expect(messages_received[3][:message].ts).to eq 103
      expect(messages_received[3][:last]).to be true
    end

    it 'triggers on_message callback for messages added even when the CLI has finished' do
      messages_received = capture_messages(
        {
          task: {
            messages: [{ ts: 100, text: 'Test message 1' }]
          }
        },
        monitoring_interval_secs: 2
      )
      # Verify callback was called correctly
      expect(messages_received.size).to eq 1
      expect(messages_received[0][:message].ts).to eq 100
      expect(messages_received[0][:last]).to be true
    end

    it 'does not trigger on_message callback when the CLI ends before creating the task\'s files' do
      expect(capture_messages({ stdout: "{\"type\":\"task_started\",\"taskId\":\"12345\"}\n" }).empty?).to be true
    end
  end
end
