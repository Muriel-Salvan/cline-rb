module Cline
  # Provide a set of wokspaces from a directory
  class Workspaces
    # @!group Public API

    Utils::EnumerableDirObjects.include_for(self, Workspace)
  end
end
