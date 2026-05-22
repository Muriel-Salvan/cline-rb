require 'forwardable'
require 'json'

module Cline
  # Cline Logs file content
  class Logs
    extend Forwardable
    include Serializable::File

    # @!group Public API

    # Fetch logs
    #
    # @param from [Time, String, nil] The horizon (exclusive) from which we select lines. Can be one of:
    #   - [Time] The timestamp to get lines from
    #   - [String] The exact log line to start after
    #   - [nil] Get all log lines
    # @return [Array<Log>] Logs list
    def logs(from: nil)
      logs_lines_from(from).map { |line| line.start_with?('{') ? Log.from_cline_json(line) : line }
    end

    # Delegates enumerating methods to the internal logs
    def_delegators :logs, *%i[[] each empty? first last size]

    # Add a new log line to the logs
    #
    # @param line [Log, String] The log entry to add (either a Log object or a raw string)
    # @return [Logs] self
    def <<(line)
      logs_lines << (line.is_a?(Log) ? line.to_cline_json : line)
      self
    end

    # Save the logs lines to the file
    def save
      raise 'This instance has not been initialized from a file' unless file

      FileUtils.mkdir_p(::File.dirname(file))
      ::File.write(file, logs_lines.map { |line| "#{line}\n" }.join)
    end

    # Monitor logs with a callback called when new or updated logs arrive
    #
    # @param on_log [#call] Block called each time there is a new log.
    #   * Param message [Log, String] Log that has happened, either as a Log object or as a String if it is not JSON.
    #   * Param last [Boolean] Is this the last log fetched from the logs?
    # @param from [Time, String, nil] The horizon (exclusive) from which we select lines (see #logs)
    # @param monitoring_interval_secs [Float] The monitoring interval in seconds
    # @yield Optional code called while monitoring is in place.
    #   If used then monitoring is stopped at the end of the block's execution.
    # @return [FileMonitor, nil] If no block has been given, return the monitor that needs to be
    #   stopped by the caller when monitoring should end.
    def monitor(on_log:, from: nil, monitoring_interval_secs: 1, &)
      # Keep the last log line that we have read
      last_log = from
      Logs.monitor_file_changes(
        file,
        on_change: proc do |_mtime|
          refresh!
          new_lines = logs_lines_from(last_log)
          unless new_lines.empty?
            last_idx = new_lines.size - 1
            new_lines.each.with_index do |line, idx|
              on_log.call(line.start_with?('{') ? Log.from_cline_json(line) : line, idx == last_idx)
            end
            last_log = new_lines.last
          end
        end,
        monitoring_interval_secs:,
        &
      )
    end

    # Clear the cache in case the log file has changed
    def refresh!
      @logs_lines = nil
    end

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(Logs) &&
        other.logs_lines == logs_lines
    end

    protected

    # Get the logs lines
    #
    # @return [Array<String>] Logs lines
    def logs_lines
      @logs_lines ||= Utils::File.safe_read(file).split("\n")
    end

    private

    # @!group Internal

    # The regexp used to match string timestamps from log lines
    LOG_ENTRY_TIME_REGEXP = /"time":"(\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\dZ)"/
    private_constant :LOG_ENTRY_TIME_REGEXP

    # Get the logs lines from a given time or line
    #
    # @param from [Time, String, nil] The horizon (exclusive) from which we select lines (see #logs)
    # @return [Array<String>] Selected logs lines
    def logs_lines_from(from = nil)
      if from
        found_reverse_idx =
          if from.is_a?(String)
            logs_lines.reverse_each.find_index(from)
          else
            horizon = from.utc.strftime('%FT%T.%LZ')
            logs_lines.reverse_each.find_index do |line|
              match = line.match(LOG_ENTRY_TIME_REGEXP)
              !match.nil? && match[1] <= horizon
            end
          end
        found_reverse_idx ? logs_lines[(logs_lines.size - found_reverse_idx)..] : logs_lines
      else
        logs_lines
      end
    end
  end
end
