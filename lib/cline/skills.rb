module Cline
  # Provide a set of skills from a directory
  class Skills
    # @!group Public API

    Utils::EnumerableDirObjects.include_for(self, Skill)
  end
end
