module Cline
  # Provide a file changes monitor.
  # Calls a callback as a separate thread for each change that happens on a file
  class FileMonitor
    # Constructor
    #
    # @param file [String] The file to monitor
    # @param on_change [#call] Block called each time there is an update.
    #   * Param mtime [Time, nil] The new file's modification time, or nil if the file is missing
    # @param monitoring_interval_secs [Float] The monitoring interval in seconds
    def initialize(file, on_change:, monitoring_interval_secs: 1)
      @file = file
      @on_change = on_change
      @monitoring_interval_secs = monitoring_interval_secs
      @monitoring = false
      @monitoring_thread = nil
    end

    # Start monitoring
    #
    # @yield Optional block that is called while monitoring has started.
    #   If this block is given, then #stop will be called automatically at the end of the block execution.
    def start
      @monitoring = true
      @monitoring_thread = Thread.new do
        file_mtime = nil
        loop do
          new_file_mtime = File.exist?(@file) ? File.mtime(@file) : nil
          if new_file_mtime != file_mtime
            # There is an update
            @on_change.call(new_file_mtime)
            file_mtime = new_file_mtime
          end
          break unless @monitoring

          sleep @monitoring_interval_secs
        end
      end
      return unless block_given?

      begin
        yield
      ensure
        stop
      end
    end

    # Stop monitoring
    def stop
      @monitoring = false
      @monitoring_thread.join
    end
  end
end
