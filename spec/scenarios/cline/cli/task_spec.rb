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
    expected_cli_options: %w[
      --plan
      --json
      --auto-approve
      --thinking high
      --compaction agentic
      --tui
      --id session-12345
      --provider openai-native
      --key sk-test-key
      --model gpt-4o
    ] +
      ['--system', 'You are a helpful assistant'] +
      %w[
        --zen
        --retries 3
        --timeout 300
        --acp
        --data-dir /tmp/cline-data
        --hooks-dir /path/to/hooks
        --worktree
        --kanban
      ],
    expected_cli_args: ['Test prompt: Create a simple Ruby class']
  )

  it 'calls the command without any prompt' do
    cli_task(prompt: nil)
    expect_issued_commands [
      ['--config', /^.+$/]
    ]
  end

  it 'calls the command with an empty prompt' do
    cli_task(prompt: '')
    expect_issued_commands [
      ['--config', /^.+$/, '']
    ]
  end

  it 'calls the command with a 1-line prompt' do
    cli_task(prompt: '1-line test prompt')
    expect_issued_commands [
      ['--config', /^.+$/, '1-line test prompt']
    ]
  end

  it 'calls the command with a multi-line prompt' do
    cli_task(prompt: "This\nis\na\nmultiline\nprompt")
    expect_issued_commands [
      ['--config', /^.+$/, "This\nis\na\nmultiline\nprompt"]
    ]
  end
end
