module Cline
  # A workspace defined in a directory
  class Workspace
    # @!group Public API

    include Serializable::Dir

    # Get the workspace settings
    #
    # @return [WorkspaceSettings, nil] The workspace settings or nil if none
    def settings
      @settings ||= WorkspaceSettings.from_cline_data(@dir)
    end

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(Workspace) &&
        other.settings == settings
    end
  end
end
