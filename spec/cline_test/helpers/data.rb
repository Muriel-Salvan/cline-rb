require 'fileutils'
require 'json'

module ClineTest
  module Helpers
    module Data
      # Provide a temporary Cline data instance over a temporary directory.
      # Will clean up the directory after code execution.
      #
      # @param global_settings [Hash, nil] The global settings file content, or nil if none
      # @param mcp_settings [Hash, nil] The MCP settings file content, or nil if none
      # @param secrets [Hash, nil] The secrets file content, or nil if none
      # @param workspaces [Hash{String => Hash{Symbol => Object}}, nil] The workspaces to create (key: name, value: data), or nil if none
      #   Workspace data is itself a hash that can describe the workspace with the following keys:
      #   * settings [Hash, nil] The settings to create, or nil if none
      # @param sessions [Hash{String => Hash{Symbol => Object}}, nil] The sessions to create (key: name, value: data), or nil if none
      #   Sessions data is itself a hash that can describe the session with the following keys:
      #   * data [Hash, nil] The session data attributes to create, or nil if none
      #   * messages [Array<Hash>, nil] The messages to create, or nil if none
      # @param tasks [Hash{String => Hash{Symbol => Object}}, nil] The tasks to create (key: name, value: data), or nil if none
      #   Tasks data is itself a hash that can describe the task with the following keys:
      #   * messages [Array<Hash>, nil] The messages to create, or nil if none
      # @param cline_models [Hash{String => Hash}, nil] The Cline models to create, or nil if none
      # @param create [Boolean] Flag to be given to the data object
      # @yield [data_dir] Block called with the data directory ready
      # @yieldparam [String] The data directory
      def with_data(global_settings: nil, mcp_settings: nil, secrets: nil, workspaces: nil, sessions: nil, tasks: nil, cline_models: nil, create: false)
        with_data_dir(global_settings:, mcp_settings:, secrets:, workspaces:, sessions:, tasks:, cline_models:) do |data_dir|
          yield Cline::Data.open(data_dir, create:)
        end
      end

      # Provide a temporary Cline data directory.
      # Will clean up the directory after code execution.
      #
      # @param global_settings [Hash, nil] The global settings file content, or nil if none
      # @param mcp_settings [Hash, nil] The MCP settings file content, or nil if none
      # @param secrets [Hash, nil] The secrets file content, or nil if none
      # @param workspaces [Hash{String => Hash{Symbol => Object}}, nil] The workspaces to create (key: name, value: data), or nil if none
      #   Workspace data is itself a hash that can describe the workspace with the following keys:
      #   * settings [Hash, nil] The settings to create, or nil if none
      # @param sessions [Hash{String => Hash{Symbol => Object}}, nil] The sessions to create (key: name, value: data), or nil if none
      #   Sessions data is itself a hash that can describe the session with the following keys:
      #   * data [Hash, nil] The session data attributes to create, or nil if none
      #   * messages [Array<Hash>, nil] The messages to create, or nil if none
      # @param tasks [Hash{String => Hash{Symbol => Object}}, nil] The tasks to create (key: name, value: data), or nil if none
      #   Tasks data is itself a hash that can describe the task with the following keys:
      #   * messages [Array<Hash>, nil] The messages to create, or nil if none
      # @param cline_models [Hash{String => Hash}, nil] The Cline models to create, or nil if none
      # @yield [data_dir] Block called with the data directory ready
      # @yieldparam [String] The data directory
      def with_data_dir(global_settings: nil, mcp_settings: nil, secrets: nil, workspaces: nil, sessions: nil, tasks: nil, cline_models: nil)
        with_temp_dir do |data_dir|
          setup_data_dir(data_dir, global_settings:, mcp_settings:, secrets:, workspaces:, sessions:, tasks:, cline_models:)
          yield data_dir
        end
      end

      # Setup an existing directory for some Cline data
      #
      # @param data_dir [String] The directory to setup
      # @param global_settings [Hash, nil] The global settings file content, or nil if none (see #with_data_dir)
      # @param mcp_settings [Hash, nil] The MCP settings file content, or nil if none (see #with_data_dir)
      # @param secrets [Hash, nil] The secrets file content, or nil if none (see #with_data_dir)
      # @param workspaces [Hash{String => Hash{Symbol => Object}}, nil] The workspaces to create (key: name, value: data), or nil if none (see #with_data_dir)
      # @param sessions [Hash{String => Hash{Symbol => Object}}, nil] The sessions to create (key: name, value: data), or nil if none (see #with_data_dir)
      # @param tasks [Hash{String => Hash{Symbol => Object}}, nil] The tasks to create (key: name, value: data), or nil if none (see #with_data_dir)
      # @param cline_models [Hash{String => Hash}, nil] The Cline models to create, or nil if none (see #with_data_dir)
      def setup_data_dir(data_dir, global_settings: nil, mcp_settings: nil, secrets: nil, workspaces: nil, sessions: nil, tasks: nil, cline_models: nil)
        File.write(File.join(data_dir, 'globalState.json'), global_settings.to_json) if global_settings
        File.write(File.join(data_dir, 'secrets.json'), secrets.to_json) if secrets
        if mcp_settings
          FileUtils.mkdir_p(File.join(data_dir, 'settings'))
          File.write(File.join(data_dir, 'settings', 'cline_mcp_settings.json'), mcp_settings.to_json)
        end
        if workspaces
          workspaces_dir = File.join(data_dir, 'workspaces')
          FileUtils.mkdir_p(workspaces_dir)
          workspaces.each do |workspace_name, workspace_data|
            workspace_dir = File.join(workspaces_dir, workspace_name)
            FileUtils.mkdir_p(workspace_dir)
            File.write(File.join(workspace_dir, 'workspaceState.json'), workspace_data[:settings].to_json) if workspace_data[:settings]
          end
        end
        if sessions
          sessions_dir = File.join(data_dir, 'sessions')
          FileUtils.mkdir_p(sessions_dir)
          sessions.each do |session_name, session_data|
            session_dir = File.join(sessions_dir, session_name)
            FileUtils.mkdir_p(session_dir)
            File.write(File.join(session_dir, "#{session_name}.json"), session_data[:data].to_json) if session_data[:data]
            if session_data[:messages]
              # SessionMessages expects a top-level JSON object with a "messages" key containing the array
              File.write(File.join(session_dir, "#{session_name}.messages.json"), { messages: session_data[:messages] }.to_json)
            end
          end
        end
        if tasks
          tasks_dir = File.join(data_dir, 'tasks')
          FileUtils.mkdir_p(tasks_dir)
          tasks.each do |task_name, task_data|
            task_dir = File.join(tasks_dir, task_name)
            FileUtils.mkdir_p(task_dir)
            File.write(File.join(task_dir, 'ui_messages.json'), task_data[:messages].to_json) if task_data[:messages]
          end
        end
        return unless cline_models

        cache_dir = File.join(data_dir, 'cache')
        FileUtils.mkdir_p(cache_dir)
        File.write(File.join(cache_dir, 'cline_models.json'), cline_models.to_json)
      end
    end
  end
end
