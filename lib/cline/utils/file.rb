require 'fileutils'
require 'tmpdir'

module Cline
  module Utils
    # Some file helpers
    module File
      # Try to read a file with retries in case other processes are using it.
      #
      # Parameters::
      # * *file* (String): Path to read
      # * *max_retries* (Integer): Number of retries in case of concurrent access [default: 3]
      # Result::
      # * String: The file content
      def self.safe_read(file, max_retries: 3)
        retries = 0
        file_content = nil
        begin
          file_content = ::File.read(file)
        rescue Errno::EACCES, Errno::EAGAIN
          # Could be that the file is being written at the same time.
          # Just try again.
          retries += 1
          raise if retries > max_retries

          sleep(0.05 * retries)
          retry
        end
        file_content
      end

      # Try to read a file and parse its JSON content with retries.
      # Uses safe_read internally, and also retries on JSON parse errors
      # (e.g. if the file was half-written when read).
      #
      # Parameters::
      # * *file* (String): Path to read
      # * *max_retries* (Integer): Number of retries for both file access and JSON parsing [default: 3]
      # Result::
      # * Object: The parsed JSON content
      def self.safe_json_read(file, max_retries: 3)
        retries = 0
        begin
          content = safe_read(file, max_retries: max_retries)
          JSON.parse(content)
        rescue JSON::ParserError
          retries += 1
          raise if retries > max_retries

          sleep(0.05 * retries)
          retry
        end
      end

      # Provide a temporary directory.
      # Will clean up the directory after code execution unless debug mode is on.
      #
      # @yield [temp_dir] Block called with the temp directory ready
      # @yieldparam temp_dir [String] The temp directory
      def self.with_temp_dir(&)
        if Cline.config.debug
          temp_dir = "#{Cline.config.temp_dir_root}/#{Time.now.utc.strftime('%Y-%m-%d-%H-%M-%S-%N')}"
          FileUtils.mkdir_p temp_dir
          yield temp_dir
        else
          Dir.mktmpdir(&)
        end
      end
    end
  end
end
