require 'tmpdir'
require 'fileutils'

module ClineTest
  module Helpers
    # Provide a temporary Cline data directory.
    # Will clean up the directory after code execution.
    #
    # @param global_settings [Hash, nil] The global settings file content, or nil if none
    # @param mcp_settings [Hash, nil] The MCP settings file content, or nil if none
    # @param workspaces [Hash{Symbol => Hash{Symbol => Object}}, nil] The workspaces to create (key: filename, value: workspace data), or nil if none
    #   Workspace data is itself a hash that can describe the workspace with the following keys:
    #   * settings [Hash, nil] The settings to create, or nil if none
    # @yield [data_dir] Block called with the data directory ready
    # @yieldparam [String] The data directory
    def with_data_dir(global_settings: nil, mcp_settings: nil, workspaces: nil)
      Dir.mktmpdir do |data_dir|
        File.write(File.join(data_dir, 'globalState.json'), global_settings.to_json) if global_settings
        if mcp_settings
          FileUtils.mkdir_p(File.join(data_dir, 'settings'))
          File.write(File.join(data_dir, 'settings', 'cline_mcp_settings.json'), mcp_settings.to_json)
        end
        if workspaces
          workspaces_dir = File.join(data_dir, 'workspaces')
          workspaces.each do |workspace_id, workspace_data|
            workspace_dir = File.join(workspaces_dir, workspace_id.to_s)
            FileUtils.mkdir_p(workspace_dir)
            File.write(File.join(workspace_dir, 'workspaceState.json'), workspace_data[:settings].to_json) if workspace_data[:settings]
          end
        end
        yield data_dir
      end
    end
  end
end
