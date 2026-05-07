describe Cline::Data, '#tasks' do
  it 'returns no tasks when no tasks directory exists in data directory' do
    with_data(tasks: nil) do |data|
      expect(data.tasks).to be_nil
    end
  end

  it 'returns Tasks instance with correct count when tasks exist' do
    with_data(
      tasks: {
        'task-1' => {},
        'task-2' => {},
        'task-3' => {}
      }
    ) do |data|
      tasks = data.tasks
      expect(tasks.size).to eq 3
      expect(tasks['task-1']).not_to be_nil
      expect(tasks['task-2']).not_to be_nil
      expect(tasks['task-3']).not_to be_nil
      expect(tasks['task-4']).to be_nil
    end
  end
end
