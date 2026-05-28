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

  # TODO: Add test cases validating calls with an empty prompt, and also multilines prompt.
end
