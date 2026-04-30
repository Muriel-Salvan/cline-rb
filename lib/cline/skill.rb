module Cline
  # A skill defined in a directory
  class Skill
    # @!group Public API

    extend Utils::InitializableFromDir

    # @!group Internal

    # Initialize this instance from a directory
    #
    # @param dir [String] The directory to be used to initialize this instance
    def initialize_from_dir(dir)
      @dir = dir
    end
  end
end
