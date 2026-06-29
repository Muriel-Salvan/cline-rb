require 'fileutils'
require 'json'

module ClineTest
  module Helpers
    module Logs
      # Provide a test Logs instance from a temporary log file.
      # Will clean up the directory after code execution.
      #
      # @param lines [Array<Hash, String>, nil] Log lines as hashes or raw JSON strings, or nil if no file
      # @yield [logs] Block called with the test logs ready
      # @yieldparam [Cline::Logs] The test logs
      def with_logs(lines: nil)
        with_temp_dir do |temp_dir|
          log_file = File.join(temp_dir, 'cline.log')
          if lines
            FileUtils.mkdir_p(File.dirname(log_file))
            File.write(
              log_file,
              lines.map do |line|
                "#{line.is_a?(Hash) ? JSON.generate(line) : line}\n"
              end.join
            )
          end
          yield Cline::Logs.open(log_file, default: '')
        end
      end

      # Helper to write log lines to the logs file
      #
      # @param logs [Cline::Logs] Logs to write lines for
      # @param lines [Array<Hash, String>, nil] Log lines to write, or nil to remove the file
      def write_logs(logs, lines)
        log_file = logs.file
        if lines
          File.write(log_file, lines.map { |line| "#{line.is_a?(String) ? line : line.to_json}\n" }.join)
        else
          FileUtils.rm_f(log_file)
        end
        # Wait for monitoring thread to pick up change
        sleep 0.1
      end

      # @return [Array<Hash{Symbol => Object}>] List of calls that have been made on on_log
      attr_reader :on_log_calls

      # Helper to capture logs from monitoring.
      # on_log calls are captured in the @on_log_calls variable
      #
      # @param logs [Logs] The logs for which we monitor
      # @param from [Time, String, nil] The filter to use when calling monitor (see Cline::Logs#monitor)
      # @yield Optional code called with monitoring in place
      def capture_on_log(logs, from: nil)
        @on_log_calls = []
        logs.monitor(
          on_log: proc do |log, last|
            on_log_calls << {
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
    end
  end
end
