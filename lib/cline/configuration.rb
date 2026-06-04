module Cline
  # Object storing a cline-rb Rubgem configuration
  class Configuration
    # @!group Public API

    # @return [Boolean] Debug mode.
    #   Defaults to `true` if `CLINE_DEBUG` environment variable is set to 1.
    attr_accessor :debug

    # @return [String] Temporary directories root for debug. Defaults to `.cline-rb/tmp`
    #   This is used only if debug is `true`.
    attr_accessor :temp_dir_root

    # @!group Internal

    # Constructor
    def initialize
      # Default values are set here
      @debug = (ENV['CLINE_DEBUG'] == '1')
      @temp_dir_root = '.cline-rb/tmp'
    end
  end
end
