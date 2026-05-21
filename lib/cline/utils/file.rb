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
    end
  end
end
