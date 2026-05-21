describe Cline::Logs, '#==' do
  it 'returns true for logs with same content' do
    log_lines = [
      { level: 30, time: '2026-01-01T00:00:00.000Z', pid: 123, hostname: 'host', name: 'test', component: 'main', msg: 'First log' },
      { level: 30, time: '2026-01-01T00:00:01.000Z', pid: 123, hostname: 'host', name: 'test', component: 'main', msg: 'Second log' }
    ]
    with_logs(lines: log_lines) do |logs1|
      with_logs(lines: log_lines) do |logs2|
        expect(logs1).not_to equal logs2
        expect(logs1).to eq logs2
      end
    end
  end

  it 'returns false for logs with different content' do
    with_logs(
      lines: [
        { level: 30, time: '2026-01-01T00:00:00.000Z', pid: 123, hostname: 'host', name: 'test', component: 'main', msg: 'First log' }
      ]
    ) do |logs1|
      with_logs(
        lines: [
          { level: 30, time: '2026-01-01T00:00:01.000Z', pid: 123, hostname: 'host', name: 'test', component: 'main', msg: 'Different log' }
        ]
      ) do |logs2|
        expect(logs1).not_to eq logs2
      end
    end
  end

  # TODO: Add 1 test case validating that 2 logs differing from 1 nested property attribute are not equal

  it 'returns false when comparing with a non-Logs object' do
    with_logs(
      lines: [
        { level: 30, time: '2026-01-01T00:00:00.000Z', pid: 123, hostname: 'host', name: 'test', component: 'main', msg: 'First log' }
      ]
    ) do |logs|
      expect(logs).not_to eq 'not a logs object'
    end
  end
end
