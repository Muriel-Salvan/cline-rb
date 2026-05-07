require_relative 'shared_examples/cli_command_examples'

describe Cline::Cli, '#task' do
  it_behaves_like(
    'a cli command',
    name: :task,
    args: ['Test task prompt: Create a simple Ruby class'],
    kwargs: {
      act: true,
      plan: false,
      yolo: true,
      auto_approve_all: true,
      timeout: 300,
      model: 'gpt-4o',
      thinking: 2048,
      reasoning_effort: 'high',
      max_consecutive_mistakes: 3,
      json: true,
      double_check_completion: true,
      auto_condense: true,
      hooks_dir: '/path/to/hooks',
      task_id: 'task-12345'
    },
    cli_options: '--act --yolo --auto-approve-all --timeout 300 --model gpt-4o ' \
                 '--thinking 2048 --reasoning-effort high --max-consecutive-mistakes 3 ' \
                 '--json --double-check-completion --auto-condense --hooks-dir /path/to/hooks ' \
                 '--taskId task-12345',
    stdin: 'Test task prompt: Create a simple Ruby class'
  )

  it 'triggers on_message callback for messages added during task execution via exec hook' do
    messages_received = []
    test_messages = [
      { ts: 100, type: 'user', text: 'Test message 1' },
      [
        # Those 2 messages will be sent at the same time
        { ts: 101, type: 'assistant', text: 'Test response 1' },
        { ts: 102, type: 'user', text: 'Test message 2' }
      ],
      { ts: 103, type: 'user', text: 'Test message 3' }
    ]
    with_config_dir do |config_dir|
      # Mock the task command with exec hook to add messages while running
      mock_commands(
        "cline task --config #{config_dir}" => {
          stdout: "{\"type\":\"task_started\",\"taskId\":\"12345\"}\n",
          exec: proc do
            sleep 0.5
            # This runs while the CLI command is executing
            task_dir = File.join(config_dir, 'data', 'tasks', '12345')
            FileUtils.mkdir_p(task_dir)
            messages_file = File.join(task_dir, 'ui_messages.json')
            # First create empty file
            File.write(messages_file, '[]')
            sleep 0.2
            # Then add test messages 1 by 1
            test_messages.size.times do |idx|
              File.write(messages_file, test_messages[0..idx].flatten(1).to_json)
              sleep 0.2
            end
          end
        }
      )
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
        monitoring_interval_secs: 0.1
      )

      # Verify callback was called correctly
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
  end
end
