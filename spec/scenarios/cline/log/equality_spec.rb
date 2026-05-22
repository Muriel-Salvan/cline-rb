describe Cline::Log, '#==' do
  it 'returns true for logs with same attributes' do
    log_line = {
      level: 30,
      time: '2026-01-01T00:00:00.000Z',
      pid: 123,
      hostname: 'host',
      name: 'test',
      component: 'main',
      msg: 'Hello world'
    }
    with_logs(lines: [log_line, log_line]) do |logs|
      log1 = logs[0]
      log2 = logs[1]
      expect(log1).not_to equal log2
      expect(log1).to eq log2
    end
  end

  it 'returns false for logs with different attributes' do
    with_logs(
      lines: [
        {
          level: 30,
          time: '2026-01-01T00:00:00.000Z',
          pid: 123,
          hostname: 'host',
          name: 'test',
          component: 'main',
          msg: 'First message'
        },
        {
          level: 40,
          time: '2026-01-01T00:00:01.000Z',
          pid: 456,
          hostname: 'other',
          name: 'test',
          component: 'other',
          msg: 'Different message'
        }
      ]
    ) do |logs|
      expect(logs[0]).not_to eq logs[1]
    end
  end

  it 'returns false for logs with 1 different unknown attribute' do
    shared_base = {
      level: 30,
      time: '2026-01-01T00:00:00.000Z',
      pid: 123,
      hostname: 'host',
      name: 'test',
      component: 'main',
      msg: 'Hello world'
    }
    with_logs(
      lines: [
        shared_base.merge(unknown_attribute: 'abc123'),
        shared_base.merge(unknown_attribute: 'def456')
      ]
    ) do |logs|
      expect(logs[0]).not_to eq logs[1]
    end
  end

  it 'returns false for logs with 1 different nested property attribute' do
    shared_base = {
      level: 30,
      time: '2026-01-01T00:00:00.000Z',
      pid: 123,
      hostname: 'host',
      name: 'test',
      component: 'main',
      msg: 'Hello world'
    }
    with_logs(
      lines: [
        shared_base.merge(properties: { ulid: 'abc123' }),
        shared_base.merge(properties: { ulid: 'def456' })
      ]
    ) do |logs|
      expect(logs[0]).not_to eq logs[1]
    end
  end

  it 'returns false for logs with 1 different unknown nested property attribute' do
    shared_base = {
      level: 30,
      time: '2026-01-01T00:00:00.000Z',
      pid: 123,
      hostname: 'host',
      name: 'test',
      component: 'main',
      msg: 'Hello world'
    }
    with_logs(
      lines: [
        shared_base.merge(properties: { ulid: 'abc123', unknown_attribute: 'value1' }),
        shared_base.merge(properties: { ulid: 'abc123', unknown_attribute: 'value2' })
      ]
    ) do |logs|
      expect(logs[0]).not_to eq logs[1]
    end
  end
end
