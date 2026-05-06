require 'stringio'
require 'tmpdir'
require 'fileutils'
require 'json'

module ClineTest
  module Helpers
    # Provide a temporary Cline data instance over a temporary directory.
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
    # @param cline_models [Hash{String => Hash}, nil] The Cline models to create, or nil if none
    # @yield [data_dir] Block called with the data directory ready
    # @yieldparam [String] The data directory
    def with_data(global_settings: nil, mcp_settings: nil, workspaces: nil, tasks: nil, cline_models: nil)
      with_data_dir(global_settings:, mcp_settings:, workspaces:, tasks:, cline_models:) do |data_dir|
        yield Cline::Data.from_dir(data_dir)
      end
    end

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
    # @param cline_models [Hash{String => Hash}, nil] The Cline models to create, or nil if none
    # @yield [data_dir] Block called with the data directory ready
    # @yieldparam [String] The data directory
    def with_data_dir(global_settings: nil, mcp_settings: nil, workspaces: nil, tasks: nil, cline_models: nil)
      Dir.mktmpdir do |data_dir|
        setup_data_dir(data_dir, global_settings:, mcp_settings:, workspaces:, tasks:, cline_models:)
        yield data_dir
      end
    end

    # Setup an existing directory for some Cline data
    #
    # @param data_dir [String] The directory to setup
    # @param global_settings [Hash, nil] The global settings file content, or nil if none (see #with_data_dir)
    # @param mcp_settings [Hash, nil] The MCP settings file content, or nil if none (see #with_data_dir)
    # @param workspaces [Hash{String => Hash{Symbol => Object}}, nil] The workspaces to create (key: name, value: data), or nil if none (see #with_data_dir)
    # @param tasks [Hash{String => Hash{Symbol => Object}}, nil] The tasks to create (key: name, value: data), or nil if none (see #with_data_dir)
    # @param cline_models [Hash{String => Hash}, nil] The Cline models to create, or nil if none (see #with_data_dir)
    def setup_data_dir(data_dir, global_settings: nil, mcp_settings: nil, workspaces: nil, tasks: nil, cline_models: nil)
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
      if tasks
        tasks_dir = File.join(data_dir, 'tasks')
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
    # @param cline_models [Hash{String => Hash}, nil] The Cline models to create, or nil if none (see #with_data_dir)
    # @yield [config_dir] Block called with the config directory ready
    # @yieldparam [String] The config directory
    def with_config_dir(skills: nil, global_settings: nil, mcp_settings: nil, workspaces: nil, tasks: nil, cline_models: nil)
      Dir.mktmpdir do |config_dir|
        setup_config_dir(config_dir, skills:, global_settings:, mcp_settings:, workspaces:, tasks:, cline_models:)
        yield config_dir
      end
    end

    # Setup an existing directory for Cline config
    #
    # @param config_dir [String] The directory to setup
    # @param skills [Hash{String => Hash{Symbol => Object}}, nil] Skills definitions (key: name, value: content)
    #   Skills data is itself a hash that can describe the skill with the following keys:
    #   * content [String, nil] The skills markdown content, or nil if none
    # @param global_settings [Hash, nil] The global settings file content, or nil if none (see #setup_data_dir)
    # @param mcp_settings [Hash, nil] The MCP settings file content, or nil if none (see #setup_data_dir)
    # @param workspaces [Hash{String => Hash{Symbol => Object}}, nil] The workspaces to create (key: name, value: data), or nil if none (see #setup_data_dir)
    # @param tasks [Hash{String => Hash{Symbol => Object}}, nil] The tasks to create (key: name, value: data), or nil if none (see #setup_data_dir)
    # @param cline_models [Hash{String => Hash}, nil] The Cline models to create, or nil if none (see #setup_data_dir)
    def setup_config_dir(config_dir, skills: nil, global_settings: nil, mcp_settings: nil, workspaces: nil, tasks: nil, cline_models: nil)
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
      setup_data_dir(data_dir, global_settings:, mcp_settings:, workspaces:, tasks:, cline_models:)
    end

    # Mock a list of commands, with their corresponding stdout, stderr and exit status.
    # This helper hides the underlying ways of running commands from Cline::Cli.
    #
    # @param commands [Hash{String => Hash{Symbol => Object}}] For each command to mock, a description of its output:
    #   * stdout [String] The stdout to be returned for this command. Defaults to ''.
    #   * stderr [String] The stderr to be returned for this command. Defaults to ''.
    #   * exit_status [Integer] The exit status to be returned for this command. Defaults to 0.
    #   * pid [Integer] The PID of the running command. Defaults to 1234.
    #   * running_time_secs [Float] The time this command runs. Defaults to 0.
    #   * exec [#call, nil] Code to be executed when this command is run, or nil if none. Defaults to nil.
    def mock_commands(commands = {})
      @issued_commands = []
      # Mock Open3.popen3 with spies pattern
      allow(Open3).to receive(:popen3) do |cmd, &block|
        command, stdin =
          if cmd =~ /^(.+) < ([^\s]+)$/
            [Regexp.last_match(1), File.read(Regexp.last_match(2))]
          else
            [cmd, nil]
          end
        issued_commands << { command:, stdin: }
        mocked_result = {
          stdout: '',
          stderr: '',
          exit_status: 0,
          pid: 1234,
          running_time_secs: 0,
          exec: nil
        }.merge(commands[command] || {})
        mocked_process_status = instance_double(Process::Status)
        allow(mocked_process_status).to receive(:exitstatus) do
          sleep mocked_result[:running_time_secs]
          mocked_result[:exec]&.call
          mocked_result[:exit_status]
        end
        block.call(
          instance_double(IO, close: nil),
          StringIO.new(mocked_result[:stdout]),
          StringIO.new(mocked_result[:stderr]),
          instance_double(
            Process::Waiter,
            pid: mocked_result[:pid],
            value: mocked_process_status
          )
        )
      end
    end

    # @return [Array<Hash{Symbol => Object}>] List of commands that have been issued:
    #   * command [String] The command itself
    #   * stdin [String, nil] The stdin that was redirected to this command, or nil if none
    attr_reader :issued_commands

    # Expect issued commands to match a list of commands
    #
    # @param expected_commands [Array<String, Hash>] The expected commands or their description:
    #   * command [String] The expected command itself (serves as the default value when used as a String instead of a Hash).
    #   * stdin [String, nil] Expected stdin content with this command, or nil if none. Defaults to nil.
    def expect_issued_commands(expected_commands)
      expect(issued_commands).to eq(
        expected_commands.map do |expected_command|
          # Normalize and set default values
          {
            stdin: nil
          }.merge(expected_command.is_a?(Hash) ? expected_command : { command: expected_command })
        end
      )
    end
  end
end
