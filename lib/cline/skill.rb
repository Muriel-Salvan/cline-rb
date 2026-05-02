module Cline
  # A skill defined in a directory
  class Skill
    # @!group Public API

    extend Utils::InitializableFromDir

    # @return [String] Skill name
    attr_reader :name

    # @!group Internal

    # Initialize this instance from a directory
    #
    # @param dir [String] The directory to be used to initialize this instance
    def initialize_from_dir(dir)
      @dir = dir
      @name = File.basename(dir)
    end

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(Skill) &&
        other.name == name
    end
  end
end
