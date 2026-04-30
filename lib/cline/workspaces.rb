module Cline
  # Provide a set of wokspaces from a directory
  class Workspaces
    Utils::EnumerableDirObjects.include_for(self, Workspace)
  end
end
