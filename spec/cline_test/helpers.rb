require 'tmpdir'
require 'fileutils'

module ClineTest
  module Helpers
    # Provide a temporary Cline data directory.
    # Will clean up the directory after code execution.
    #
    # @param global_settings [Hash, nil] The global settings file content, or nil if none
    # @param mcp_settings [Hash, nil] The MCP settings file content, or nil if none
    # @yield [data_dir] Block called with the data dir ready
    # @yieldparam [String] The data directory
    def with_data_dir(global_settings: nil, mcp_settings: nil)
      Dir.mktmpdir do |data_dir|
        File.write(File.join(data_dir, 'globalState.json'), global_settings.to_json) if global_settings
        if mcp_settings
          FileUtils.mkdir_p(File.join(data_dir, 'settings'))
          File.write(File.join(data_dir, 'settings', 'cline_mcp_settings.json'), mcp_settings.to_json)
        end
        yield data_dir
      end
    end
  end
end
