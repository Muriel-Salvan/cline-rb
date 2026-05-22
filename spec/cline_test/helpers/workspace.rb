module ClineTest
  module Helpers
    module Workspace
      # Provide a test workspace
      #
      # @param name [String] The workspace name
      # @param settings [Hash, nil] The workspace settings, or nil if none
      # @yield [workspace] Block called with the test workspace ready
      # @yieldparam [Cline::Workspace] The test workspace
      def with_workspace(name: 'test-workspace', settings: nil)
        with_data(
          workspaces: {
            name => {
              settings:
            }
          }
        ) do |data|
          yield data.workspaces[name]
        end
      end
    end
  end
end
