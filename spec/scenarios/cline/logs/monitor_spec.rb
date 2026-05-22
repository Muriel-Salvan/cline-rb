require 'fileutils'

describe Cline::Logs, '#monitor' do
  it 'calls on_log for each log line even without modifications' do
    with_logs(
      lines: [
        { msg: 'First log' },
        { msg: 'Second log' }
      ]
    ) do |logs|
      capture_on_log(logs)
      expect(calls.size).to eq 2
      expect(calls[0][:log].msg).to eq 'First log'
      expect(calls[0][:last]).to be false
      expect(calls[1][:log].msg).to eq 'Second log'
      expect(calls[1][:last]).to be true
    end
  end

  it 'calls on_log when file is created after monitoring starts' do
    with_logs(lines: nil) do |logs|
      capture_on_log(logs) do
        # Now create the log file
        write_logs(
          logs,
          [
            { msg: 'Log after create' }
          ]
        )
      end
      expect(calls.size).to eq 1
      expect(calls[0][:log].msg).to eq 'Log after create'
      expect(calls[0][:last]).to be true
    end
  end

  it 'calls on_log only for new lines when adding new log lines' do
    with_logs(
      lines: [
        { msg: 'First log' },
        { msg: 'Second log' }
      ]
    ) do |logs|
      capture_on_log(logs) do
        calls.clear
        # Add new log lines
        write_logs(
          logs,
          [
            { msg: 'First log' },
            { msg: 'Second log' },
            { msg: 'Third log' },
            { msg: 'Fourth log' }
          ]
        )
      end
      # Only new lines should be called
      expect(calls.size).to eq 2
      expect(calls[0][:log].msg).to eq 'Third log'
      expect(calls[0][:last]).to be false
      expect(calls[1][:log].msg).to eq 'Fourth log'
      expect(calls[1][:last]).to be true
    end
  end

  it 'calls on_log only for new lines when log lines also include raw strings' do
    with_logs(
      lines: [
        { 'msg' => 'First log' },
        { 'msg' => 'Second log' },
        'Pre-existing raw string'
      ]
    ) do |logs|
      capture_on_log(logs) do
        calls.clear
        # Add new log lines with raw string keys and a raw string entry
        write_logs(
          logs,
          [
            { 'msg' => 'First log' },
            { 'msg' => 'Second log' },
            'Pre-existing raw string',
            { 'msg' => 'Third log' },
            'Raw log string',
            { 'msg' => 'Fourth log' }
          ]
        )
      end
      # Only new lines should be called (Third log, Raw log string, Fourth log)
      expect(calls.size).to eq 3
      expect(calls[0][:log].msg).to eq 'Third log'
      expect(calls[0][:last]).to be false
      expect(calls[1][:log]).to eq 'Raw log string'
      expect(calls[1][:last]).to be false
      expect(calls[2][:log].msg).to eq 'Fourth log'
      expect(calls[2][:last]).to be true
    end
  end

  it 'starts monitoring from a given time horizon' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First log' },
        { time: '2026-01-01T00:00:01.000Z', msg: 'Second log' }
      ]
    ) do |logs|
      capture_on_log(logs, from: Time.utc(2026, 1, 1, 0, 0, 0, 500_000))
      expect(calls.size).to eq 1
      expect(calls[0][:log].msg).to eq 'Second log'
      expect(calls[0][:last]).to be true
    end
  end

  it 'starts monitoring from a given string horizon' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First log' },
        { time: '2026-01-01T00:00:01.000Z', msg: 'Second log' }
      ]
    ) do |logs|
      capture_on_log(logs, from: '{"time":"2026-01-01T00:00:00.000Z","msg":"First log"}')
      expect(calls.size).to eq 1
      expect(calls[0][:log].msg).to eq 'Second log'
      expect(calls[0][:last]).to be true
    end
  end

  it 'returns only new lines when using a Time horizon' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First log' },
        { time: '2026-01-01T00:00:01.000Z', msg: 'Second log' }
      ]
    ) do |logs|
      capture_on_log(logs, from: Time.utc(2026, 1, 1, 0, 0, 0, 500_000)) do
        calls.clear
        # Add new log lines
        write_logs(
          logs,
          [
            { time: '2026-01-01T00:00:00.000Z', msg: 'First log' },
            { time: '2026-01-01T00:00:01.000Z', msg: 'Second log' },
            { time: '2026-01-01T00:00:02.000Z', msg: 'Third log' },
            { time: '2026-01-01T00:00:03.000Z', msg: 'Fourth log' }
          ]
        )
      end
      # Only new lines after the horizon should be called
      expect(calls.size).to eq 2
      expect(calls[0][:log].msg).to eq 'Third log'
      expect(calls[0][:last]).to be false
      expect(calls[1][:log].msg).to eq 'Fourth log'
      expect(calls[1][:last]).to be true
    end
  end

  it 'returns only new lines when using a String horizon' do
    with_logs(
      lines: [
        { time: '2026-01-01T00:00:00.000Z', msg: 'First log' },
        { time: '2026-01-01T00:00:01.000Z', msg: 'Second log' }
      ]
    ) do |logs|
      capture_on_log(logs, from: '{"time":"2026-01-01T00:00:01.000Z","msg":"Second log"}') do
        calls.clear
        # Add new log lines
        write_logs(
          logs,
          [
            { time: '2026-01-01T00:00:00.000Z', msg: 'First log' },
            { time: '2026-01-01T00:00:01.000Z', msg: 'Second log' },
            { time: '2026-01-01T00:00:02.000Z', msg: 'Third log' },
            { time: '2026-01-01T00:00:03.000Z', msg: 'Fourth log' }
          ]
        )
      end
      # Only new lines after the horizon should be called
      expect(calls.size).to eq 2
      expect(calls[0][:log].msg).to eq 'Third log'
      expect(calls[0][:last]).to be false
      expect(calls[1][:log].msg).to eq 'Fourth log'
      expect(calls[1][:last]).to be true
    end
  end

  it 'returns monitor object when no block given and stops monitoring after #stop is called' do
    with_logs(lines: nil) do |logs|
      @calls = []
      monitor = logs.monitor(
        on_log: proc do |log, last|
          calls << {
            log: log,
            last: last
          }
        end,
        monitoring_interval_secs: 0.01
      )
      # Wait for monitoring thread to start
      sleep 0.05
      # First write should trigger on_log call
      write_logs(logs, [{ msg: 'First log' }])
      sleep 0.05
      expect(calls.size).to eq 1
      calls.clear
      # Stop the monitor
      monitor.stop
      # Second write should NOT trigger on_log call after stop
      write_logs(
        logs,
        [
          { msg: 'First log' },
          { msg: 'Second log' }
        ]
      )
      sleep 0.05
      expect(calls).to be_empty
    end
  end
end
