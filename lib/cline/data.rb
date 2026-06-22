require 'json'

module Cline
  # Accesses the content of a Cline data directory.
  # Wraps for example the content of ~/.cline/data
  class Data
    # @!group Public API

    include Serializable::Dir

    # Get the VSCode plugin Cline data dir
    #
    # @return [Data, nil] The data for the installed VSCode plugin, or nil if none
    def self.vscode
      @vscode ||= Data.open(
        "#{
          ENV['VSCODE_PORTABLE'] ? "#{ENV['VSCODE_PORTABLE']}/user-data" : "#{Utils::Os.user_app_data_dir}/Code"
        }/User/globalStorage/saoudrizwan.claude-dev"
      )
    end

    # Get the cached Cline models
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [Models] Cached Cline models
    def cline_models(create: self.create)
      @cline_models ||= Models.from_cline_data(dir, create:)
    end

    # Get global settings stored in this data directory
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [GlobalSettings, nil] Global settings stored in this data directory, or nil if none
    def global_settings(create: self.create)
      @global_settings ||= GlobalSettings.from_cline_data(dir, create:)
    end

    # Get global state stored in this data directory
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [GlobalState, nil] Global state stored in this data directory, or nil if none
    def global_state(create: self.create)
      @global_state ||= GlobalState.from_cline_data(dir, create:)
    end

    # Get the Cline logs
    #
    # @return [Logs] The Cline logs
    def logs(create: self.create)
      @logs ||= Logs.open(subpath('logs/cline.log'), default: create ? '' : nil)
    end

    # Get MCP settings stored in this data directory
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [McpSettings, nil] MCP settings stored in this data directory, or nil if none
    def mcp_settings(create: self.create)
      @mcp_settings ||= McpSettings.from_cline_data(dir, create:)
    end

    # Get providers stored in this data directory
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [Providers, nil] Providers stored in this data directory, or nil if none
    def providers(create: self.create)
      @providers ||= Providers.from_cline_data(dir, create:)
    end

    # Get secrets stored in this data directory
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [Secrets, nil] Secrets stored in this data directory, or nil if none
    def secrets(create: self.create)
      @secrets ||= Secrets.from_cline_data(dir, create:)
    end

    # Get sessions from this data directory
    #
    # @param cline_models [Models] The Cline models used to interpret the sessions' messages
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [Sessions] Set of sessions associated to this data directory
    def sessions(cline_models: self.cline_models, create: self.create)
      @sessions ||= Sessions.open(subpath('sessions'), cline_models:, create:)
    end

    # Get tasks from this data directory
    #
    # @param cline_models [Models] The Cline models used to interpret the tasks' messages
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [Tasks] Set of tasks associated to this data directory
    def tasks(cline_models: self.cline_models, create: self.create)
      @tasks ||= Tasks.open(subpath('tasks'), cline_models:, create:)
    end

    # Get workspaces from this data directory
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [Workspaces] Set of workspaces associated to this data directory
    def workspaces(create: self.create)
      @workspaces ||= Workspaces.open(subpath('workspaces'), create:)
    end

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(Data) &&
        other.tasks == tasks &&
        other.workspaces == workspaces &&
        other.cline_models == cline_models &&
        other.global_settings == global_settings &&
        other.global_state == global_state &&
        other.mcp_settings == mcp_settings &&
        other.providers == providers &&
        other.secrets == secrets
    end
  end
end
