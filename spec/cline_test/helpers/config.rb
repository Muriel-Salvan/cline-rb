require 'fileutils'

module ClineTest
  module Helpers
    module Config
      # Provide a temporary Cline config instance over a temporary directory.
      # Will clean up the directory after code execution.
      #
      # @param skills [Hash{String => Hash{Symbol => Object}}, nil] Skills definitions (key: name, value: content)
      #   Skills data is itself a hash that can describe the skill with the following keys:
      #   * content [String, nil] The skills markdown content, or nil if none
      #   * files [Hash{String => String}, nil] Additional files to create in the skill directory (key: relative path, value: file content)
      # @param cline_models [Hash{String => Hash}, nil] The Cline models to create, or nil if none (see #with_data_dir)
      # @param global_settings [Hash, nil] The global settings file content, or nil if none (see #with_data_dir)
      # @param mcp_settings [Hash, nil] The MCP settings file content, or nil if none (see #with_data_dir)
      # @param sessions [Hash{String => Hash{Symbol => Object}}, nil] The sessions to create (key: name, value: data), or nil if none (see #with_data_dir)
      # @param tasks [Hash{String => Hash{Symbol => Object}}, nil] The tasks to create (key: name, value: data), or nil if none (see #with_data_dir)
      # @param workspaces [Hash{String => Hash{Symbol => Object}}, nil] The workspaces to create (key: name, value: data), or nil if none (see #with_data_dir)
      # @param create [Boolean] Should the data be instantiated with the create option?
      # @yield [config] Block called with the test config ready
      # @yieldparam [Cline::Config] The test config
      def with_config(skills: nil, cline_models: nil, global_settings: nil, mcp_settings: nil, sessions: nil, tasks: nil, workspaces: nil, create: false)
        with_config_dir(skills:, cline_models:, global_settings:, mcp_settings:, sessions:, tasks:, workspaces:) do |config_dir|
          yield Cline::Config.open(config_dir, create:)
        end
      end

      # Provide a temporary Cline config directory.
      # Will clean up the directory after code execution.
      #
      # @param skills [Hash{String => Hash{Symbol => Object}}, nil] Skills definitions (key: name, value: content)
      #   Skills data is itself a hash that can describe the skill with the following keys:
      #   * content [String, nil] The skills markdown content, or nil if none
      #   * files [Hash{String => String}, nil] Additional files to create in the skill directory (key: relative path, value: file content)
      # @param cline_models [Hash{String => Hash}, nil] The Cline models to create, or nil if none (see #with_data_dir)
      # @param global_settings [Hash, nil] The global settings file content, or nil if none (see #with_data_dir)
      # @param mcp_settings [Hash, nil] The MCP settings file content, or nil if none (see #with_data_dir)
      # @param sessions [Hash{String => Hash{Symbol => Object}}, nil] The sessions to create (key: name, value: data), or nil if none (see #with_data_dir)
      # @param tasks [Hash{String => Hash{Symbol => Object}}, nil] The tasks to create (key: name, value: data), or nil if none (see #with_data_dir)
      # @param workspaces [Hash{String => Hash{Symbol => Object}}, nil] The workspaces to create (key: name, value: data), or nil if none (see #with_data_dir)
      # @yield [config_dir] Block called with the config directory ready
      # @yieldparam [String] The config directory
      def with_config_dir(skills: nil, cline_models: nil, global_settings: nil, mcp_settings: nil, sessions: nil, tasks: nil, workspaces: nil)
        with_temp_dir do |config_dir|
          setup_config_dir(config_dir, skills:, cline_models:, global_settings:, mcp_settings:, sessions:, tasks:, workspaces:)
          yield config_dir
        end
      end

      # Setup an existing directory for Cline config
      #
      # @param config_dir [String] The directory to setup
      # @param skills [Hash{String => Hash{Symbol => Object}}, nil] Skills definitions (key: name, value: content)
      #   Skills data is itself a hash that can describe the skill with the following keys:
      #   * content [String, nil] The skills markdown content, or nil if none
      #   * files [Hash{String => String}, nil] Additional files to create in the skill directory (key: relative path, value: file content)
      # @param cline_models [Hash{String => Hash}, nil] The Cline models to create, or nil if none (see #with_data_dir)
      # @param global_settings [Hash, nil] The global settings file content, or nil if none (see #with_data_dir)
      # @param mcp_settings [Hash, nil] The MCP settings file content, or nil if none (see #with_data_dir)
      # @param sessions [Hash{String => Hash{Symbol => Object}}, nil] The sessions to create (key: name, value: data), or nil if none (see #with_data_dir)
      # @param tasks [Hash{String => Hash{Symbol => Object}}, nil] The tasks to create (key: name, value: data), or nil if none (see #with_data_dir)
      # @param workspaces [Hash{String => Hash{Symbol => Object}}, nil] The workspaces to create (key: name, value: data), or nil if none (see #with_data_dir)
      def setup_config_dir(config_dir, skills: nil, cline_models: nil, global_settings: nil, mcp_settings: nil, sessions: nil, tasks: nil, workspaces: nil)
        if skills
          skills_dir = File.join(config_dir, 'skills')
          FileUtils.mkdir_p(skills_dir)
          skills.each do |skill_name, skill_data|
            # Set default values
            skill_data = {
              files: []
            }.merge(skill_data)
            skill_dir = File.join(skills_dir, skill_name)
            FileUtils.mkdir_p(skill_dir)
            File.write(File.join(skill_dir, 'SKILL.md'), skill_data[:content]) if skill_data[:content]
            skill_data[:files].each do |file_path, file_content|
              full_path = File.join(skill_dir, file_path)
              FileUtils.mkdir_p(File.dirname(full_path))
              File.write(full_path, file_content)
            end
          end
        end
        data_dir = File.join(config_dir, 'data')
        FileUtils.mkdir_p(data_dir)
        setup_data_dir(data_dir, cline_models:, global_settings:, mcp_settings:, sessions:, tasks:, workspaces:)
      end
    end
  end
end
