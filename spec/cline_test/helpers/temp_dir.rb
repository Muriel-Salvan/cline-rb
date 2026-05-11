require 'fileutils'
require 'tmpdir'

module ClineTest
  module Helpers
    # Helpers handling temporary directories for test cases
    module TempDir
      # @return [String] Temporary directory path that can be used for local temporary files created by test cases
      def temp_dir_path
        '.cline_test/tmp'
      end

      # Provide a temporary directory.
      # Will clean up the directory after code execution.
      #
      # @yield [temp_dir] Block called with the temp directory ready
      # @yieldparam [String] The temp directory
      def with_temp_dir(&)
        if Debug.debug?
          temp_dir = "#{temp_dir_path}/#{Time.now.utc.strftime('%Y-%m-%d-%H-%M-%S-%N')}"
          FileUtils.mkdir_p temp_dir
          yield temp_dir
        else
          Dir.mktmpdir(&)
        end
      end

      # Clean the temporary directory.
      # This is useful before every test case to ensure isolation.
      def clean_temp_dir
        FileUtils.rm_rf temp_dir_path
      end
    end
  end
end
