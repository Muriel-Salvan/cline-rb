module Cline
  module Utils
    module Os
      # OS utils for host OS mingw32
      module Mingw32
        # Get the user home directory path
        #
        # @return [String] Normalized absolute path to user home directory
        def user_home_dir
          ENV['USERPROFILE'].gsub('\\', '/')
        end

        # Kill a process.
        # Handles errors gracefully in case the process has already disappeared.
        #
        # @param pid [Integer] Process to kill
        def kill(pid)
          # Don't use Process.kill on Windows, because the killed process will have an exit status 0, which is incorrect.
          # TODO: Use Process.kill here when Process.kill will be fixed on Windows systems.
          system("taskkill /f /pid #{pid}")
        end
      end
    end
  end
end
