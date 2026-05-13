describe Cline::Tasks, '#new' do
  it 'creates a new task and its directory from scratch' do
    with_data(tasks: {}) do |data|
      tasks = data.tasks
      task = tasks.new('my-task')
      expect(File.directory?(File.join(tasks.dir, 'my-task'))).to be true
      expect(tasks['my-task']).to eq(task)
    end
  end

  it 'uses existing task content when called with an existing sub-directory name' do
    with_data(
      tasks: {
        'my-task' => {
          messages: [
            { ts: 123_456, type: 'user', text: 'Hello' }
          ]
        }
      },
      create: true
    ) do |data|
      tasks = data.tasks
      task = tasks.new('my-task')
      expect(tasks['my-task'].messages.first.ts).to eq(123_456)
      expect(task.messages.first.ts).to eq(123_456)
    end
  end

  it 'creates child message objects when accessed on a newly created task' do
    with_data(tasks: {}) do |data|
      tasks = data.tasks
      task = tasks.new('my-task')
      # Check that children messages have indeed been created
      expect(File.exist?(File.join(task.dir, 'ui_messages.json'))).to be false
      messages = task.messages
      expect(File.exist?(File.join(task.dir, 'ui_messages.json'))).to be true
      expect(messages).not_to be_nil
      expect(messages).to be_empty
    end
  end
end
