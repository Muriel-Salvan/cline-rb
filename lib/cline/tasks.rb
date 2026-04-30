module Cline
  # Provide a set of tasks from a directory
  class Tasks
    Utils::EnumerableDirObjects.include_for(self, Task)
  end
end
