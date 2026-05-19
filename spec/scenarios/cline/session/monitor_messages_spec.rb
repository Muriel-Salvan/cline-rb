require 'fileutils'

describe Cline::Session, '#monitor_messages' do
  # Helper to write messages to session directory
  #
  # @param session [Cline::Session] Session to write messages for
  # @param messages [Array<Hash>, nil] Messages to write
  def write_messages(session, messages)
    # TODO: Messages should contain the whole JSON, not just the messages property
    json_file = File.join(session.dir, 'test-session.messages.json')
    if messages
      # Wrap messages inside the top-level JSON object expected by SessionMessages
      File.write(json_file, { messages: }.to_json)
    else
      FileUtils.rm_f(json_file)
    end
    # Wait for monitoring thread to pick up change
    sleep 0.1
  end

  # @return [Array<Hash{Symbol => Object}>] List of calls that have been made on on_message
  attr_reader :calls

  # Helper to capture messages from a session's monitoring messages.
  # on_message calls are captured in the @calls variable
  #
  # @param session [Session] The session for which we monitor the messages
  # @yield Optional code called with monitoring in place
  def capture_on_message(session)
    @calls = []
    session.monitor_messages(
      on_message: proc do |message, last, previous_version|
        calls << {
          message: message,
          last: last,
          previous_version: previous_version
        }
      end,
      monitoring_interval_secs: 0.01
    ) do
      # Wait for the monitoring thread to have started
      sleep 0.05
      yield if block_given?
      # Wait for the monitoring thread to eventually catch-up on updates
      sleep 0.05
    end
  end

  it 'calls on_message for each message even without modifications' do
    with_session(
      messages: [
        { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'First message' }], ts: 100 },
        { id: 'msg-2', role: 'assistant', content: [{ type: 'text', text: 'Response' }], ts: 101 }
      ]
    ) do |session|
      capture_on_message(session)
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
    with_session(messages: nil) do |session|
      capture_on_message(session) do
        # Now create the messages file
        write_messages(
          session,
          [
            { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'Message after create' }], ts: 100 }
          ]
        )
      end
      expect(calls.size).to eq 1
      expect(calls[0][:message].ts).to eq 100
      expect(calls[0][:last]).to be true
      expect(calls[0][:previous_version]).to be_nil
    end
  end

  # TODO: Add test case validating that it does not call on_message when root attributes of the messages JSON file are updated

  it 'calls on_message only for new messages when adding new messages' do
    with_session(
      messages: [
        { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'First message' }], ts: 100 },
        { id: 'msg-2', role: 'assistant', content: [{ type: 'text', text: 'Response' }], ts: 101 }
      ]
    ) do |session|
      capture_on_message(session) do
        calls.clear
        # Add new messages
        write_messages(
          session,
          [
            { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'First message' }], ts: 100 },
            { id: 'msg-2', role: 'assistant', content: [{ type: 'text', text: 'Response' }], ts: 101 },
            { id: 'msg-3', role: 'user', content: [{ type: 'text', text: 'Second question' }], ts: 102 },
            { id: 'msg-4', role: 'assistant', content: [{ type: 'text', text: 'Second response' }], ts: 103 }
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
    with_session(
      messages: [
        { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'First message' }], ts: 100 },
        { id: 'msg-2', role: 'assistant', content: [{ type: 'text', text: 'Original response' }], ts: 101 },
        { id: 'msg-3', role: 'user', content: [{ type: 'text', text: 'Second message' }], ts: 102 }
      ]
    ) do |session|
      original_message = nil
      capture_on_message(session) do
        # Save original message for previous_version check
        original_message = session.messages[1]
        calls.clear
        # Modify only the middle message
        write_messages(
          session, [
            { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'First message' }], ts: 100 },
            { id: 'msg-2', role: 'assistant', content: [{ type: 'text', text: 'Updated response' }], ts: 101 },
            { id: 'msg-3', role: 'user', content: [{ type: 'text', text: 'Second message' }], ts: 102 }
          ]
        )
      end
      expect(calls.size).to eq 1
      expect(calls[0][:message].ts).to eq 101
      expect(calls[0][:message].content.first.text).to eq 'Updated response'
      expect(calls[0][:last]).to be false
      expect(calls[0][:previous_version]).to eq original_message
    end
  end

  it 'updates session.messages accessor with new content when messages are monitored' do
    # TODO: Add a new test case like this one, but when modifying root attribnutes of the message file
    with_session(
      messages: [
        { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'First message' }], ts: 100 }
      ]
    ) do |session|
      expect(session.messages.size).to eq 1
      capture_on_message(session) do
        write_messages(
          session, [
            { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'First message' }], ts: 100 },
            { id: 'msg-2', role: 'assistant', content: [{ type: 'text', text: 'New message' }], ts: 101 }
          ]
        )
      end
      expect(session.messages.size).to eq 2
      expect(session.messages[1].ts).to eq 101
      expect(session.messages[1].content.first.text).to eq 'New message'
    end
  end

  it 'returns monitor object when no block given and stops monitoring after #stop is called' do
    with_session(messages: nil) do |session|
      @calls = []
      monitor = session.monitor_messages(
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
      write_messages(session, [{ id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'First message' }], ts: 100 }])
      sleep 0.05
      expect(calls.size).to eq 1
      calls.clear
      # Stop the monitor
      monitor.stop
      # Second write should NOT trigger on_message call after stop
      write_messages(
        session,
        [
          { id: 'msg-1', role: 'user', content: [{ type: 'text', text: 'First message' }], ts: 100 },
          { id: 'msg-2', role: 'user', content: [{ type: 'text', text: 'Second message' }], ts: 101 }
        ]
      )
      sleep 0.05
      expect(calls).to be_empty
    end
  end
end
