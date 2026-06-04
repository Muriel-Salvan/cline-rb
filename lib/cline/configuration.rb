module Cline
  # Object storing a cline-rb Rubgem configuration
  class Configuration
    # @!group Public API

    # @return [Boolean] Debug mode.
    #   Defaults to `true` if `CLINE_DEBUG` environment variable is set to 1.
    attr_accessor :debug

    # @!group Internal

    # Constructor
    def initialize
      # Default values are set here
      @debug = (ENV['CLINE_DEBUG'] == '1')
    end
  end
end
