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

        # @return [String] The Cline executable
        def cline_exe
          'cline.cmd'
        end

        # @return [String] The user applications data directory
        def user_app_data_dir
          ENV['APPDATA'] || raise('APPDATA environment variable should be set to know the applications data dir')
        end
      end
    end
  end
end
