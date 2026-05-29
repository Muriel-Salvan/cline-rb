require_relative 'shared_examples/cli_command_examples'

describe Cline::Cli, '#task' do
  it_behaves_like(
    'a cli command',
    name: :task,
    args: ['Test prompt: Create a simple Ruby class'],
    kwargs: {
      plan: true,
      json: true,
      auto_approve: true,
      thinking: 'high',
      compaction: 'agentic',
      tui: true,
      id: 'session-12345',
      provider: 'openai-native',
      key: 'sk-test-key',
      model: 'gpt-4o',
      system: 'You are a helpful assistant',
      zen: true,
      retries: 3,
      timeout: 300,
      acp: true,
      data_dir: '/tmp/cline-data',
      hooks_dir: '/path/to/hooks',
      worktree: true,
      kanban: true
    },
    expected_cli_options: '--plan --json --auto-approve --thinking high ' \
      '--compaction agentic --tui --id session-12345 --provider openai-native ' \
      '--key sk-test-key --model gpt-4o --system You are a helpful assistant ' \
      '--zen --retries 3 --timeout 300 --acp --data-dir /tmp/cline-data ' \
      '--hooks-dir /path/to/hooks --worktree --kanban',
    expected_cli_args: 'Test prompt: Create a simple Ruby class'
  )

  context 'with an empty prompt' do
    it 'calls the command without any prompt argument' do
      cli_task(prompt: '')
      issued_command = issued_commands.first
      expect(issued_command[:command]).to match(/--config [^\s]+$/)
      expect(issued_command[:stdin]).to be_nil
    end
  end

  context 'with a multiline prompt' do
    it 'uses a file to store the prompt content' do
      result = cli_task(
        prompt: "Line 1\nLine 2",
        stub: {
          eval: <<~EO_RUBY
            puts "Received prompt: \#{File.read(ARGV.last).inspect}"
          EO_RUBY
        }
      )
      issued_command = issued_commands.first
      expect(issued_command[:command]).to match(/--config [^\s]+ [^\s]+$/)
      expect(issued_command[:stdin]).to be_nil
      expect(result[:stdout]).to include 'Received prompt: "Line 1\nLine 2"'
    end
  end
end
