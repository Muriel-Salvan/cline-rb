module Cline
  # Provide a set of sessions from a directory
  class Sessions
    include Utils::EnumerableDirObjects

    # Constructor
    #
    # @param cline_models [Models] The Cline models used to interpret the sessions' messages
    def initialize(cline_models:)
      @cline_models = cline_models
    end

    private

    # Get an object and its name from a sub-directory
    #
    # @param dir [String] The directory containing the object
    # @param create [Boolean] Should the instance be created if it does not exist?
    # @return [Array(String, Object)] Return 2 values:
    #   0. [String] The object name
    #   1. [Object] The object itself
    def object_from(dir, create:)
      [File.basename(dir), Session.open(dir, cline_models: @cline_models, create:)]
    end
  end
end
