require 'json'

describe Cline::Message, '#to_human' do
  # Create a task with a JSON message, and provide the corresponding human message for expectations.
  #
  # @param ts [Integer] The JSON message ts field
  # @param type [String] The JSON message type field
  # @param kwargs [Hash{Symbol => Object}] Additional JSON message fields
  # @return [String] The corresponding human message
  def human_message(ts: 123_456, type: 'say', **kwargs)
    result = nil
    with_task(messages: [{ ts:, type:, **kwargs }]) do |task|
      result = task.messages.first.to_human
    end
    result
  end

  it 'converts text messages to human format' do
    expect(
      human_message(
        say: 'text',
        text: "This is a test message\nwith multiple lines"
      )
    ).to eq('This is a test message with multiple lines')
  end

  it 'converts task messages to human format' do
    expect(
      human_message(
        say: 'task',
        text: 'Test task description'
      )
    ).to eq('Test task description')
  end

  it 'converts command messages to human format' do
    expect(
      human_message(
        say: 'command',
        text: 'bundle exec rspec spec/'
      )
    ).to eq('Command: bundle exec rspec spec/')
  end

  it 'converts command output messages to human format' do
    expect(
      human_message(
        say: 'command_output',
        text: 'Test command output'
      )
    ).to eq('Command output: Test command output')
  end

  it 'converts error messages to human format' do
    expect(
      human_message(
        say: 'error',
        text: 'Something went wrong'
      )
    ).to eq('Error: Something went wrong')
  end

  it 'converts reasoning messages to human format' do
    expect(
      human_message(
        say: 'reasoning',
        text: 'Analyzing the problem'
      )
    ).to eq('Reasoning: Analyzing the problem')
  end

  it 'converts user feedback messages to human format' do
    expect(
      human_message(
        say: 'user_feedback',
        text: 'Great job!'
      )
    ).to eq('User feedback: Great job!')
  end

  it 'converts api_req_retried messages to human format' do
    expect(
      human_message(
        say: 'api_req_retried',
        text: ''
      )
    ).to eq('API request retried')
  end

  it 'converts task progress messages to human format' do
    expect(
      human_message(
        say: 'task_progress',
        text: "- [x] Step 1\n- [x] Step 2\n- [ ] Step 3"
      )
    ).to eq('Task progress: 2/3 tasks')
  end

  it 'converts completion result messages to human format' do
    expect(
      human_message(
        say: 'completion_result',
        text: 'Task completed successfully'
      )
    ).to eq('Task completed: Task completed successfully')
  end

  it 'converts readFile tool messages to human format' do
    expect(
      human_message(
        say: 'tool',
        text: JSON.generate(
          tool: 'readFile',
          path: 'lib/cline/message.rb',
          content: 'File content here'
        )
      )
    ).to include('[readFile] - lib/cline/message.rb')
  end

  it 'converts searchFiles tool messages to human format' do
    expect(
      human_message(
        say: 'tool',
        text: JSON.generate(
          tool: 'searchFiles',
          path: 'spec/',
          regex: 'to_human'
        )
      )
    ).to eq('[searchFiles] - spec/ (regex: to_human)')
  end

  it 'converts ask followup messages to human format' do
    expect(
      human_message(
        type: 'ask',
        ask: 'followup',
        text: JSON.generate(
          question: 'Which option?',
          options: ['Option 1', 'Option 2']
        )
      )
    ).to eq('Ask user: Follow-up - Which option? - Options: Option 1, Option 2')
  end

  it 'respects character limit parameter' do
    long_text = 'a' * 200
    with_task(
      messages: [
        {
          ts: 123_456,
          type: 'say',
          say: 'text',
          text: long_text
        }
      ]
    ) do |task|
      result = task.messages.first.to_human(limit: 50)
      expect(result.length).to be <= 50
      expect(result).to include('...')
    end
  end

  it 'handles multi-line content correctly' do
    expect(
      human_message(
        say: 'text',
        text: "Line 1\nLine 2\nLine 3\r\nLine 4"
      )
    ).to eq('Line 1 Line 2 Line 3 Line 4')
  end
end
