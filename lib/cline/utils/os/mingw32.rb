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
      end
    end
  end
end
