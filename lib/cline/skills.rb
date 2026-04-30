module Cline
  # Provide a set of skills from a directory
  class Skills
    Utils::EnumerableDirObjects.include_for(self, Skill)
  end
end
