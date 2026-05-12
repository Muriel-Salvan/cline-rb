module Cline
  # Provide a set of tasks from a directory
  class Tasks
    include Utils::EnumerableDirObjects

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
    # @return [Array(String, Object)] Return 2 values:
    #   0. [String] The object name
    #   1. [Object] The object itself
    def object_from(dir)
      [File.basename(dir), Task.open(dir, cline_models: @cline_models)]
    end
  end
end
