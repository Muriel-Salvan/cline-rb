require 'fileutils'

describe Cline::Logs, '#monitor' do
  # Helper to write log lines to the logs file
  #
  # @param logs [Cline::Logs] Logs to write lines for
  # @param lines [Array<Hash>, nil] Log lines to write, or nil to remove the file
  def write_logs(logs, lines)
    log_file = logs.file
    if lines
      File.write(log_file, lines.map { |line| "#{line.to_json}\n" }.join)
    else
      FileUtils.rm_f(log_file)
    end
    # Wait for monitoring thread to pick up change
    sleep 0.1
  end

  # @return [Array<Hash{Symbol => Object}>] List of calls that have been made on on_log
  attr_reader :calls

  # Helper to capture logs from monitoring.
  # on_log calls are captured in the @calls variable
  #
  # @param logs [Logs] The logs for which we monitor
  # @param from [Time, String, nil] The filter to use when calling monitor (see Cline::Logs#monitor)
  # @yield Optional code called with monitoring in place
  def capture_on_log(logs, from: nil)
    @calls = []
    logs.monitor(
      on_log: proc do |log, last|
        calls << {
          log: log,
          last: last
        }
      end,
      monitoring_interval_secs: 0.01,
      from:
    ) do
      # Wait for the monitoring thread to have started
      sleep 0.05
      yield if block_given?
      # Wait for the monitoring thread to eventually catch-up on updates
      sleep 0.05
    end
  end

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

  it 'starts monitoring from a given horizon' do
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

  # TODO: Add 1 test case validating a String horizon
  # TODO: Add 1 test case validating only new lines get returned (in the capture_log block), while also using a Time horizon
  # TODO: Add 1 test case validating only new lines get returned (in the capture_log block), while also using a String horizon

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
