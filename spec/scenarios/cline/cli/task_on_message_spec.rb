describe Cline::Cli, '#task' do
  describe 'the on_message callback' do
    # Run a Cline's task and capture all the messages received by the on_message callback
    #
    # @param mock_config [Hash{Symbol => Object}] The Cline mock configuration (see #ClineTest::Helpers::Cli#mock_commands)
    # @param monitoring_interval_secs [Float] The monitoring interval in seconds.
    # @param sleep [Float] Some time between logging the session ID and creating the session files,
    #   so that monitoring thread can catch up (useful to validate last session messages).
    # @return [Array<Hash{Symbol => Object}>] The list of messages received by the on_message callback:
    #   * message [SessionMessage] The message that was received.
    #   * last [Boolean] Is this message the last one of the discussion?
    #   * previous_version [SessionMessage, nil] Previous version of this message, or nil if it is a new one.
    def capture_messages(mock_config = {}, monitoring_interval_secs: 0.05, sleep: 0)
      # Always create a log entry so that we find the session
      cli_task(monitoring_interval_secs:, stub: [{ log: {}, sleep: }, mock_config])
      messages_received
    end

    it 'triggers on_message callback for messages added during task execution' do
      messages_received = capture_messages(
        {
          session: {
            messages: [
              { ts: 100, content: [{ text: 'Test message 1' }] },
              [
                # Those 2 messages will be sent at the same time
                { ts: 101, content: [{ text: 'Test response 1' }] },
                { ts: 102, content: [{ text: 'Test message 2' }] }
              ],
              { ts: 103, content: [{ text: 'Test message 3' }] }
            ]
          }
        },
        sleep: 1
      )
      expect(messages_received.size).to eq 5
      expect(messages_received[0][:message].role).to eq 'user'
      expect(messages_received[0][:last]).to be true
      expect(messages_received[1][:message].ts).to eq 100
      expect(messages_received[1][:last]).to be true
      expect(messages_received[2][:message].ts).to eq 101
      expect(messages_received[2][:last]).to be false
      expect(messages_received[3][:message].ts).to eq 102
      expect(messages_received[3][:last]).to be true
      expect(messages_received[4][:message].ts).to eq 103
      expect(messages_received[4][:last]).to be true
    end

    it 'triggers on_message callback for messages added even when the CLI has finished' do
      messages_received = capture_messages(
        { session: { messages: [{ ts: 100, content: [{ text: 'Test message 1' }] }] } },
        monitoring_interval_secs: 2
      )
      # Verify callback was called correctly
      expect(messages_received.size).to eq 2
      expect(messages_received[0][:message].role).to eq 'user'
      expect(messages_received[0][:last]).to be false
      expect(messages_received[1][:message].ts).to eq 100
      expect(messages_received[1][:last]).to be true
    end

    it 'does not trigger on_message callback when the CLI ends before creating the session\'s files' do
      expect(capture_messages.empty?).to be true
    end
  end
end
