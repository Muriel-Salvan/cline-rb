module Cline
  module Utils
    module Os
      # OS utils for host OS linux
      module Linux
        include Logger

        # Get the user home directory path
        #
        # @return [String] Normalized absolute path to user home directory
        def user_home_dir
          @user_home_dir ||= `eval echo ~$USER`.strip
        end

        # Kill a process
        # Handles errors gracefully in case the process has already disappeared.
        #
        # @param pid [Integer] Process to kill
        def kill(pid)
          Process.kill('TERM', pid)
        rescue Errno::ESRCH
          # Could be that the process naturally died before we interrupted it
          log_debug "Process #{pid} was already killed"
        end

        # @return [Array<String>] The Cline executable command line (can also have some arguments)
        def cline_exe
          ['cline']
        end

        # @return [String] The user applications data directory
        def user_app_data_dir
          "#{user_home_dir}/.config"
        end

        # @return [Integer] Maximum length a command line can have
        def max_cmd_length
          @max_cmd_length ||= Integer(`getconf ARG_MAX`.strip)
        end
      end
    end
  end
end
