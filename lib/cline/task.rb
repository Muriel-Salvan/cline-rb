require 'fileutils'
require 'json'

module Cline
  # A task defined in a directory
  class Task
    # @!group Public API

    extend Utils::InitializableFromDir

    # Get the task's messages
    #
    # @return [Messages, nil] The task's messages, or nil if none
    def messages
      @messages ||= Messages.json_from_base_dir(@task_dir, cline_models: @cline_models)
    end

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(Task) &&
        other.messages == messages
    end

    # @!group Internal

    # Constructor
    #
    # @param cline_models [Models] The Cline models used to interpret the tasks' messages
    def initialize(cline_models:)
      @cline_models = cline_models
    end

    # Initialize this instance from a directory
    #
    # @param dir [String] The directory to be used to initialize this instance
    def initialize_from_dir(dir)
      @task_dir = dir
    end
  end
end
