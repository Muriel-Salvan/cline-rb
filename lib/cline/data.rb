require 'json'

module Cline
  # Accesses the content of a Cline data directory.
  # Wraps for example the content of ~/.cline/data
  class Data
    # @!group Public API

    include Serializable::Dir

    # Get workspaces from this data directory
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [Workspaces] Set of workspaces associated to this data directory
    def workspaces(create: self.create)
      @workspaces ||= Workspaces.open(subpath('workspaces'), create:)
    end

    # Get tasks from this data directory
    #
    # @param cline_models [Models] The Cline models used to interpret the tasks' messages
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [Tasks] Set of tasks associated to this data directory
    def tasks(cline_models: self.cline_models, create: self.create)
      @tasks ||= Tasks.open(subpath('tasks'), cline_models:, create:)
    end

    # Get sessions from this data directory
    #
    # @param cline_models [Models] The Cline models used to interpret the sessions' messages
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [Sessions] Set of sessions associated to this data directory
    def sessions(cline_models: self.cline_models, create: self.create)
      @sessions ||= Tasks.open(subpath('sessions'), cline_models:, create:)
    end

    # Get global settings stored in this data directory
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [GlobalSettings, nil] Global settings stored in this data directory, or nil if none
    def global_settings(create: self.create)
      @global_settings ||= GlobalSettings.from_cline_data(dir, create:)
    end

    # Get secrets stored in this data directory
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [Secrets, nil] Secrets stored in this data directory, or nil if none
    def secrets(create: self.create)
      @secrets ||= Secrets.from_cline_data(dir, create:)
    end

    # Get MCP settings stored in this data directory
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [McpSettings, nil] MCP settings stored in this data directory, or nil if none
    def mcp_settings(create: self.create)
      @mcp_settings ||= McpSettings.from_cline_data(dir, create:)
    end

    # Get the cached Cline models
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [Models] Cached Cline models
    def cline_models(create: self.create)
      @cline_models ||= Models.from_cline_data(dir, create:)
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
