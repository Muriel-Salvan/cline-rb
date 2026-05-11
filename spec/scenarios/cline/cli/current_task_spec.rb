describe Cline::Cli, '#current_task' do
  it 'is nil when no task has been started' do
    expect(described_class.new.current_task).to be_nil
  end

  it 'is set after running a task' do
    with_config_dir do |config_dir|
      mock_commands("cline --config #{config_dir}" => { task: {} })
      cli = described_class.new(config: config_dir)
      cli.task('Test prompt')
      expect(cli.current_task).not_to be_nil
    end
  end

  it 'returns the task\'s messages after running a task' do
    with_config_dir do |config_dir|
      mock_commands(
        "cline --config #{config_dir}" => {
          task: { messages: [{ ts: 100, text: 'Test message' }] }
        }
      )
      cli = described_class.new(config: config_dir)
      cli.task('Test prompt')
      expect(cli.current_task.messages.first.ts).to eq 100
    end
  end

  it 'is set correctly inside the on_message callback' do
    with_config_dir do |config_dir|
      mock_commands(
        "cline --config #{config_dir}" => {
          task: { messages: [{ ts: 100, text: 'Test message' }] }
        }
      )
      captured_task = nil
      cli = described_class.new(config: config_dir)
      cli.task(
        'Test prompt',
        on_message: proc do |_message, _last, _previous|
          captured_task = cli.current_task
        end,
        monitoring_interval_secs: 0.1
      )
      expect(captured_task).not_to be_nil
      expect(captured_task).to eq(cli.current_task)
    end
  end
end
