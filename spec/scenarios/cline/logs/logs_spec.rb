describe Cline::Logs, '#logs' do
  it 'returns all logs when no from parameter is given' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First' },
        { time: '2026-01-01T00:00:01.000Z', msg: 'Second' },
        { time: '2026-01-01T00:00:02.000Z', msg: 'Third' }
      ]
    ) do |logs|
      result = logs.logs
      expect(result.size).to eq 3
      expect(result[0].msg).to eq 'First'
      expect(result[1].msg).to eq 'Second'
      expect(result[2].msg).to eq 'Third'
    end
  end

  it 'filters logs from a given Time horizon' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First' },
        { time: '2026-01-01T00:00:01.000Z', msg: 'Second' },
        { time: '2026-01-01T00:00:02.000Z', msg: 'Third' }
      ]
    ) do |logs|
      # Get logs after '2026-01-01T00:00:00.500Z' -> should return Second and Third
      result = logs.logs(from: Time.utc(2026, 1, 1, 0, 0, 0, 500_000))
      expect(result.size).to eq 2
      expect(result[0].msg).to eq 'Second'
      expect(result[1].msg).to eq 'Third'
    end
  end

  it 'filters logs from a given Time horizon, excluding the horizon itself' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First' },
        { time: '2026-01-01T00:00:01.000Z', msg: 'Second' },
        { time: '2026-01-01T00:00:02.000Z', msg: 'Third' }
      ]
    ) do |logs|
      # Get logs after '2026-01-01T00:00:01.000Z' -> should return Third
      result = logs.logs(from: Time.utc(2026, 1, 1, 0, 0, 1))
      expect(result.size).to eq 1
      expect(result[0].msg).to eq 'Third'
    end
  end

  it 'filters logs from a given String horizon' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First' },
        { time: '2026-01-01T00:00:01.000Z', msg: 'Second' },
        { time: '2026-01-01T00:00:02.000Z', msg: 'Third' }
      ]
    ) do |logs|
      # Get logs after the first log line string -> should return Second and Third
      result = logs.logs(from: '{"time":"2026-01-01T00:00:00.000Z","msg":"First"}')
      expect(result.size).to eq 2
      expect(result[0].msg).to eq 'Second'
      expect(result[1].msg).to eq 'Third'
    end
  end

  it 'returns all logs when from horizon is before all logs and no match is found' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First' },
        { time: '2026-01-01T00:00:01.000Z', msg: 'Second' }
      ]
    ) do |logs|
      # Time before all logs -> no matching line found, returns all logs
      result = logs.logs(from: Time.utc(2025, 12, 31))
      expect(result.size).to eq 2
      expect(result[0].msg).to eq 'First'
      expect(result[1].msg).to eq 'Second'
    end
  end

  it 'returns all logs when from string line does not match any line' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First' }
      ]
    ) do |logs|
      result = logs.logs(from: 'non-existent-line')
      expect(result.size).to eq 1
      expect(result[0].msg).to eq 'First'
    end
  end

  it 'returns empty array when there are no logs after the from horizon' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First' },
        { time: '2026-01-01T00:00:01.000Z', msg: 'Second' }
      ]
    ) do |logs|
      # Time after all logs -> the last line matches (its time < horizon), so returns empty after it
      result = logs.logs(from: Time.utc(2026, 1, 1, 0, 0, 2))
      expect(result).to be_empty
    end
  end

  it 'returns empty array when from string is the last line' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First' }
      ]
    ) do |logs|
      result = logs.logs(from: '{"time":"2026-01-01T00:00:00.000Z","msg":"First"}')
      expect(result).to be_empty
    end
  end

  # TODO: Add 1 test case validating returning all logs with non-JSON lines
  # TODO: Add 1 test case validating returning filtered logs using a String with non-JSON lines among the logs
  # TODO: Add 1 test case validating returning filtered logs using a Time with non-JSON lines among the logs

  it 'delegates enumerating methods to the internal logs' do
    # TODO: Move this test to another file
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First' },
        { time: '2026-01-01T00:00:01.000Z', msg: 'Second' },
        { time: '2026-01-01T00:00:02.000Z', msg: 'Third' }
      ]
    ) do |logs|
      expect(logs.size).to eq 3
      expect(logs.first.msg).to eq 'First'
      expect(logs.last.msg).to eq 'Third'
      expect(logs[1].msg).to eq 'Second'
      expect(logs.empty?).to be false
    end
  end
end
