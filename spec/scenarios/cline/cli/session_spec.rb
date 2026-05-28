describe Cline::Cli, '#session' do
  it 'is nil when no task has been started' do
    expect(described_class.new.session).to be_nil
  end

  it 'is set after running a task' do
    cli_task(stub: { log: {}, session: {} }) do |cli|
      expect(cli.session).not_to be_nil
      expect(cli.session.session_id).to eq 'test-session-id'
    end
  end

  it 'returns the session\'s messages after running a task' do
    cli_task(stub: { log: {}, session: { messages: [{ ts: 100, content: [{ text: 'Test message' }] }] } }) do |cli|
      message = cli.session.messages.first
      expect(message.ts).to eq 100
      expect(message.content.first.text).to eq 'Test message'
    end
  end

  it 'is set correctly inside the on_message callback' do
    with_config do |config|
      mock_commands(
        "--config #{config.dir} Test prompt" => {
          log: {},
          session: { messages: [{ ts: 100, content: [{ text: 'Test message' }] }] }
        }
      )
      captured_session = nil
      cli = described_class.new(config: config.dir)
      cli.task(
        'Test prompt',
        on_message: proc do |_message, _last, _previous|
          captured_session = cli.session
        end,
        monitoring_interval_secs: 0.1
      )
      expect(captured_session).not_to be_nil
      expect(captured_session).to eq(cli.session)
    end
  end
end
