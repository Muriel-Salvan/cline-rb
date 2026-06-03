require 'fileutils'

module ClineTest
  module Helpers
    module Config
      # Provide a temporary Cline config instance over a temporary directory.
      # Will clean up the directory after code execution.
      #
      # @param create [Boolean] Should the data be instantiated with the create option?
      # @param include_project_config [Boolean] Should we include the project config option?
      # @param skills [Hash{String => Hash{Symbol => Object}}, nil] Skills definitions (key: name, value: content)
      #   Skills data is itself a hash that can describe the skill with the following keys:
      #   * content [String, nil] The skills markdown content, or nil if none
      #   * files [Hash{String => String}, nil] Additional files to create in the skill directory (key: relative path, value: file content)
      # @param data_kwargs [Hash{Symbol => Object}] The data initialization kwargs (see #setup_data_dir)
      # @yield [config] Block called with the test config ready
      # @yieldparam [Cline::Config] The test config
      def with_config(create: false, include_project_config: false, skills: nil, **data_kwargs)
        with_temp_dir do |config_dir|
          setup_config_dir(config_dir, skills:, **data_kwargs)
          yield Cline::Config.open(config_dir, create:, include_project_config:)
        end
      end

      # Setup an existing directory for Cline config
      #
      # @param config_dir [String] The directory to setup
      # @param skills [Hash{String => Hash{Symbol => Object}}, nil] Skills definitions (key: name, value: content)
      #   Skills data is itself a hash that can describe the skill with the following keys:
      #   * content [String, nil] The skills markdown content, or nil if none
      #   * files [Hash{String => String}, nil] Additional files to create in the skill directory (key: relative path, value: file content)
      # @param data_kwargs [Hash{Symbol => Object}] The data initialization kwargs (see #setup_data_dir)
      def setup_config_dir(config_dir, skills: nil, **data_kwargs)
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
        setup_data_dir(data_dir, **data_kwargs)
      end
    end
  end
end
