describe Cline::Task, '#==' do
  it 'returns true when 2 tasks from different data directories have the same messages' do
    messages_array = [
      { ts: 12_345, type: 'user', text: 'Hello' },
      { ts: 12_346, type: 'assistant', text: 'Hi' }
    ]

    with_task(messages: messages_array) do |task1|
      with_task(name: 'test-task-2', messages: messages_array) do |task2|
        # Tasks are from different data directories but have identical messages
        expect(task1).not_to equal(task2) # Different instances
        expect(task1).to eq(task2)
        expect(task1.messages).not_to equal(task2.messages)
        expect(task1.messages).to eq(task2.messages)
      end
    end
  end

  it 'returns false when 2 tasks have different message attributes' do
    with_task(messages: [{ ts: 123, type: 'user', text: 'Hello' }]) do |task1|
      with_task(messages: [{ ts: 123, type: 'user', text: 'Different' }]) do |task2|
        expect(task1).not_to eq(task2)
        expect(task1.messages).not_to eq(task2.messages)
      end
    end
  end

  it 'returns false when 2 tasks have different message attributes that are unknown' do
    with_task(messages: [{ ts: 123, type: 'user', text: 'Hello', unknown_attribute: 1 }]) do |task1|
      with_task(messages: [{ ts: 123, type: 'user', text: 'Hello', unknown_attribute: 2 }]) do |task2|
        expect(task1).not_to eq(task2)
        expect(task1.messages).not_to eq(task2.messages)
      end
    end
  end
end
