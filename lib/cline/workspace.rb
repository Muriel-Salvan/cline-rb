module Cline
  # A workspace defined in a directory
  class Workspace
    # @!group Public API

    extend Utils::InitializableFromDir

    # Get the workspace settings
    #
    # @return [WorkspaceSettings, nil] The workspace settings or nil if none
    def settings
      @settings ||= WorkspaceSettings.json_from_base_dir(@workspace_dir)
    end

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(Workspace) &&
        other.settings == settings
    end

    # @!group Internal

    # Initialize this instance from a directory
    #
    # @param dir [String] The directory to be used to initialize this instance
    def initialize_from_dir(dir)
      @workspace_dir = dir
    end
  end
end
