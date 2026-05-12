module Cline
  # A skill defined in a directory
  class Skill
    # @!group Public API

    include Serializable::Dir

    # Get the skill's name
    #
    # @return [String] Skill name
    def name
      File.basename(@dir)
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
