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
    end
  end
end
