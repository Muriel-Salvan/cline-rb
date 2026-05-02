require 'tmpdir'
require 'fileutils'
require 'json'

module ClineTest
  module Helpers
    # Provide a temporary Cline data directory.
    # Will clean up the directory after code execution.
    #
    # @param global_settings [Hash, nil] The global settings file content, or nil if none
    # @param mcp_settings [Hash, nil] The MCP settings file content, or nil if none
    # @param workspaces [Hash{String => Hash{Symbol => Object}}, nil] The workspaces to create (key: name, value: data), or nil if none
    #   Workspace data is itself a hash that can describe the workspace with the following keys:
    #   * settings [Hash, nil] The settings to create, or nil if none
    # @param tasks [Hash{String => Hash{Symbol => Object}}, nil] The tasks to create (key: name, value: data), or nil if none
    #   Tasks data is itself a hash that can describe the task with the following keys:
    #   * messages [Array<Hash>, nil] The messages to create, or nil if none
    # @yield [data_dir] Block called with the data directory ready
    # @yieldparam [String] The data directory
    def with_data_dir(global_settings: nil, mcp_settings: nil, workspaces: nil, tasks: nil)
      Dir.mktmpdir do |data_dir|
        setup_data_dir(data_dir, global_settings:, mcp_settings:, workspaces:, tasks:)
        yield data_dir
      end
    end

    # Provide a temporary Cline config directory.
    # Will clean up the directory after code execution.
    #
    # @param skills [Hash{String => Hash{Symbol => Object}}, nil] Skills definitions (key: name, value: content)
    #   Skills data is itself a hash that can describe the skill with the following keys:
    #   * content [String, nil] The skills markdown content, or nil if none
    # @param global_settings [Hash, nil] The global settings file content, or nil if none (see #with_data_dir)
    # @param mcp_settings [Hash, nil] The MCP settings file content, or nil if none (see #with_data_dir)
    # @param workspaces [Hash{String => Hash{Symbol => Object}}, nil] The workspaces to create (key: name, value: data), or nil if none (see #with_data_dir)
    # @param tasks [Hash{String => Hash{Symbol => Object}}, nil] The tasks to create (key: name, value: data), or nil if none (see #with_data_dir)
    # @yield [config_dir] Block called with the config directory ready
    # @yieldparam [String] The config directory
    def with_config_dir(skills: nil, global_settings: nil, mcp_settings: nil, workspaces: nil, tasks: nil)
      Dir.mktmpdir do |config_dir|
        if skills
          skills_dir = File.join(config_dir, 'skills')
          skills.each do |skill_name, skill_data|
            skill_dir = File.join(skills_dir, skill_name)
            FileUtils.mkdir_p(skill_dir)
            File.write(File.join(skill_dir, 'SKILL.md'), skill_data[:content]) if skill_data[:content]
          end
        end
        data_dir = File.join(config_dir, 'data')
        FileUtils.mkdir_p(data_dir)
        setup_data_dir(data_dir, global_settings:, mcp_settings:, workspaces:, tasks:)
        yield config_dir
      end
    end

    private

    # Setup an existing directory for some Cline data
    #
    # @param data_dir [String] The directory to setup
    # @param global_settings [Hash, nil] The global settings file content, or nil if none (see #with_data_dir)
    # @param mcp_settings [Hash, nil] The MCP settings file content, or nil if none (see #with_data_dir)
    # @param workspaces [Hash{String => Hash{Symbol => Object}}, nil] The workspaces to create (key: name, value: data), or nil if none (see #with_data_dir)
    # @param tasks [Hash{String => Hash{Symbol => Object}}, nil] The tasks to create (key: name, value: data), or nil if none (see #with_data_dir)
    def setup_data_dir(data_dir, global_settings: nil, mcp_settings: nil, workspaces: nil, tasks: nil)
      File.write(File.join(data_dir, 'globalState.json'), global_settings.to_json) if global_settings
      if mcp_settings
        FileUtils.mkdir_p(File.join(data_dir, 'settings'))
        File.write(File.join(data_dir, 'settings', 'cline_mcp_settings.json'), mcp_settings.to_json)
      end
      if workspaces
        workspaces_dir = File.join(data_dir, 'workspaces')
        workspaces.each do |workspace_name, workspace_data|
          workspace_dir = File.join(workspaces_dir, workspace_name)
          FileUtils.mkdir_p(workspace_dir)
          File.write(File.join(workspace_dir, 'workspaceState.json'), workspace_data[:settings].to_json) if workspace_data[:settings]
        end
      end
      return unless tasks

      tasks_dir = File.join(data_dir, 'tasks')
      tasks.each do |task_name, task_data|
        task_dir = File.join(tasks_dir, task_name)
        FileUtils.mkdir_p(task_dir)
        File.write(File.join(task_dir, 'ui_messages.json'), task_data[:messages].to_json) if task_data[:messages]
      end
    end
  end
end
