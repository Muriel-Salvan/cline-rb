module Cline
  module Utils
    module Os
      # OS utils for host OS linux
      module Linux
        # Get the user home directory path
        #
        # @return [String] Normalized absolute path to user home directory
        def user_home_dir
          `eval echo ~$USER`.strip
        end
      end
    end
  end
end
