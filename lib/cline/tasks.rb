module Cline
  # Provide a set of tasks from a directory
  class Tasks
    # @!group Public API

    include Utils::EnumerableDirObjects

    # @!group Internal

    # Constructor
    #
    # @param cline_models [Models] The Cline models used to interpret the tasks' messages
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
      [File.basename(dir), Task.open(dir, cline_models: @cline_models, create:)]
    end
  end
end
