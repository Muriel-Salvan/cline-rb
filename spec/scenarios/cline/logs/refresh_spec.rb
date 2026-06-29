describe Cline::Logs, '#refresh!' do
  it 'loads new log lines after external file modification' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First' },
        { time: '2026-01-01T00:00:01.000Z', msg: 'Second' }
      ]
    ) do |logs|
      expect(logs.size).to eq 2

      # Simulate an external write to the log file
      write_logs(
        logs,
        [
          { time: '2026-01-01T00:00:00.000Z', msg: 'First' },
          { time: '2026-01-01T00:00:01.000Z', msg: 'Second' },
          { time: '2026-01-01T00:00:02.000Z', msg: 'Third' }
        ]
      )

      # Current ones are still cached
      expect(logs.size).to eq 2

      logs.refresh!

      result = logs.logs
      expect(result.size).to eq 3
      expect(result[0].msg).to eq 'First'
      expect(result[1].msg).to eq 'Second'
      expect(result[2].msg).to eq 'Third'
    end
  end

  it 'loads replaced log lines after external file rewrite' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'Old' }
      ]
    ) do |logs|
      expect(logs.size).to eq 1
      expect(logs.first.msg).to eq 'Old'

      # Completely rewrite the log file with different content
      write_logs(
        logs,
        [
          { time: '2026-01-01T00:00:00.000Z', msg: 'New' }
        ]
      )

      logs.refresh!

      result = logs.logs
      expect(result.size).to eq 1
      expect(result[0].msg).to eq 'New'
    end
  end

  it 'loads log lines after external file truncation' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First' }
      ]
    ) do |logs|
      expect(logs.size).to eq 1

      # Truncate the file externally
      write_logs(logs, [])

      logs.refresh!
      expect(logs.size).to eq 0
    end
  end

  it 'is idempotent when called multiple times' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First' }
      ]
    ) do |logs|
      expect(logs.size).to eq 1

      logs.refresh!
      logs.refresh!
      # File hasn't changed, should still return the same content
      expect(logs.size).to eq 1
      expect(logs.first.msg).to eq 'First'
    end
  end

  it 'without refresh! returns stale cached content' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'Original' }
      ]
    ) do |logs|
      # Cache the content by calling a method that reads from the file
      expect(logs.size).to eq 1

      # Modify the log file externally but do NOT call refresh!
      write_logs(
        logs,
        [
          { time: '2026-01-01T00:00:00.000Z', msg: 'Modified' }
        ]
      )

      # Without refresh!, we should still see the old cached content
      expect(logs.size).to eq 1
      expect(logs.first.msg).to eq 'Original'
    end
  end

  it 'is called by monitor when log file changes' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First' },
        { time: '2026-01-01T00:00:01.000Z', msg: 'Second' }
      ]
    ) do |logs|
      capture_on_log(logs, from: Time.utc(2026, 1, 1, 0, 0, 1)) do
        write_logs(
          logs,
          [
            { time: '2026-01-01T00:00:00.000Z', msg: 'First' },
            { time: '2026-01-01T00:00:01.000Z', msg: 'Second' },
            { time: '2026-01-01T00:00:02.000Z', msg: 'Third' }
          ]
        )
      end

      expect(on_log_calls.size).to eq 1
      expect(on_log_calls[0][:log].msg).to eq 'Third'
      expect(on_log_calls[0][:last]).to be true
    end
  end
end
