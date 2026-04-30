require 'json'

module Cline
  # Accesses the content of a Cline data directory.
  # Wraps for example the content of ~/.cline/data
  class Data
    # @!group Public API

    extend Utils::InitializableFromDir

    # Get workspaces from this data directory
    #
    # @return [Workspaces] Set of workspaces associated to this data directory
    def workspaces
      @workspaces ||= Workspaces.from_dir(File.join(@data_dir, 'workspaces'))
    end

    # Get tasks from this data directory
    #
    # @return [Tasks] Set of tasks associated to this data directory
    def tasks
      @tasks ||= Tasks.from_dir(File.join(@data_dir, 'tasks'))
    end

    # Get global settings stored in this data directory
    #
    # @return [GlobalSettings, nil] Global settings stored in this data directory, or nil if none
    def global_settings
      @global_settings ||= GlobalSettings.json_from_base_dir(@data_dir)
    end

    # Get MCP settings stored in this data directory
    #
    # @return [McpSettings, nil] MCP settings stored in this data directory, or nil if none
    def mcp_settings
      @mcp_settings ||= McpSettings.json_from_base_dir(@data_dir)
    end

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(Data) &&
        other.workspaces == workspaces &&
        other.tasks == tasks &&
        other.global_settings == global_settings &&
        other.mcp_settings == mcp_settings
    end

    # @!group Internal

    # Initialize this instance from a directory
    #
    # @param dir [String] The directory to be used to initialize this instance
    def initialize_from_dir(dir)
      @data_dir = dir
    end
  end
end
