require 'forwardable'

module Cline
  # Accesses all configuration of a Cline directory.
  # Wraps for example the content of ~/.cline
  class Config
    extend Forwardable

    # @!group Public API

    extend Utils::InitializableFromDir

    # Give access to the data getters
    def_delegators :data, *%i[workspaces tasks global_settings mcp_settings]

    # Get skills from this config
    #
    # @return [Skills] Set of skills
    def skills
      @skills ||= Skills.from_dir(File.join(@config_dir, 'skills'))
    end

    # Get the data directory from this config
    #
    # @return [Data] The Cline data directory content
    def data
      @data ||= Data.from_dir(File.join(@config_dir, 'data'))
    end

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(Config) &&
        other.skills == skills &&
        other.data == data
    end

    # @!group Internal

    # Initialize this instance from a directory
    #
    # @param dir [String] The directory to be used to initialize this instance
    def initialize_from_dir(dir)
      @config_dir = dir
    end
  end
end
