require 'json'

module Cline
  # Accesses the content of a Cline data directory.
  # Wraps for example the content of ~/.cline/data
  class Data
    # @!group Public API

    include Serializable::Dir

    # Get workspaces from this data directory
    #
    # @return [Workspaces] Set of workspaces associated to this data directory
    def workspaces
      @workspaces ||= Workspaces.open(subdir('workspaces'))
    end

    # Get tasks from this data directory
    #
    # @param cline_models [Models] The Cline models used to interpret the tasks' messages
    # @return [Tasks] Set of tasks associated to this data directory
    def tasks(cline_models: self.cline_models)
      @tasks ||= Tasks.open(subdir('tasks'), cline_models:)
    end

    # Get global settings stored in this data directory
    #
    # @return [GlobalSettings, nil] Global settings stored in this data directory, or nil if none
    def global_settings
      @global_settings ||= GlobalSettings.from_cline_data(@dir)
    end

    # Get secrets stored in this data directory
    #
    # @return [Secrets, nil] Secrets stored in this data directory, or nil if none
    def secrets
      @secrets ||= Secrets.from_cline_data(@dir)
    end

    # Get MCP settings stored in this data directory
    #
    # @return [McpSettings, nil] MCP settings stored in this data directory, or nil if none
    def mcp_settings
      @mcp_settings ||= McpSettings.from_cline_data(@dir)
    end

    # Get the cached Cline models
    #
    # @return [Models] Cached Cline models
    def cline_models
      @cline_models ||= Models.from_cline_data(@dir)
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
        other.mcp_settings == mcp_settings &&
        other.secrets == secrets &&
        other.cline_models == cline_models
    end
  end
end
