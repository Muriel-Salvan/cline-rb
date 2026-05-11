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
    expected_cli: 'cline',
    expected_cli_options: '--act --yolo --auto-approve-all --timeout 300 --model gpt-4o ' \
      '--thinking 2048 --reasoning-effort high --max-consecutive-mistakes 3 ' \
      '--json --double-check-completion --auto-condense --hooks-dir /path/to/hooks ' \
      '--taskId task-12345',
    expected_stdin: 'Test task prompt: Create a simple Ruby class'
  )
end
