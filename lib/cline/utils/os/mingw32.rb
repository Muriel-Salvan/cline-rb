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

        # @return [Array<String>] The Cline executable command line (can also have some arguments)
        def cline_exe
          # As this CLI will be used with PTY.spawn and we want multiline support,
          # don't use cline.cmd npm wrapper as it treats "\n" as new command lines.
          # Therefore we use the node.exe binary directly.
          @cline_exe ||= [
            'node.exe',
            "#{::File.dirname(`where cline.cmd`.split("\n").first)}/node_modules/cline/bin/cline"
          ]
        end

        # @return [String] The user applications data directory
        def user_app_data_dir
          ENV['APPDATA'] || raise('APPDATA environment variable should be set to know the applications data dir')
        end
      end
    end
  end
end
