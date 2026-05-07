require 'fileutils'

describe Cline::Data, '#tasks #monitor_messages' do
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
