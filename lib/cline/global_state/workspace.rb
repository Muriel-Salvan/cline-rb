module Cline
  class GlobalState
    # Workspace directories and multi-root configuration
    module Workspace
      # Workspace root directory entry
      class WorkspaceRoot < Schema
        # @!group Public API

        # @return [String] Directory path
        attribute :path, :string

        # @return [String] Display name
        attribute :name, :string

        # @return [String] Version control system type
        attribute :vcs, :string

        # @return [String] Current commit hash
        attribute :commit_hash, :string
      end

      # Define all the attributes of the included class
      #
      # @param base [Class] Base class including this mixin
      def self.included(base)
        base.class_eval do
          # @!group Public API

          # @return [Array<WorkspaceRoot>] List of workspace root directories
          attribute :workspace_roots, Utils::Schema.collection(WorkspaceRoot)

          # @return [Integer] Index of currently active primary workspace root
          attribute :primary_root_index, :integer

          # @return [Boolean] Flag enabling multi root workspace support
          attribute :multi_root_enabled, :boolean
        end
      end
    end
  end
end
