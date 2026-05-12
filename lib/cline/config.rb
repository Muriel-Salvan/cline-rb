require 'forwardable'

module Cline
  # Accesses all configuration of a Cline directory.
  # Wraps for example the content of ~/.cline
  class Config
    extend Forwardable

    # @!group Public API

    # Get the global Cline config
    #
    # @return [Config] The global config for the current user
    def self.global
      @global ||= Config.open("#{Utils::Os.user_home_dir}/.cline")
    end

    # Get the local Cline config
    #
    # @return [Config] The local config for the current repository
    def self.local
      @local ||= Config.open('.cline')
    end

    include Serializable::Dir

    # Give access to the data getters
    def_delegators :data, *%i[global_settings mcp_settings tasks workspaces]

    # Get skills from this config
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [Skills] Set of skills
    def skills(create: self.create)
      @skills ||= Skills.open(subdir('skills'), create:)
    end

    # Get the data directory from this config
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [Data] The Cline data directory content
    def data(create: self.create)
      @data ||= Data.open(subdir('data'), create:)
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

    # Remove caches.
    def refresh!
      @skills = nil
      @data = nil
    end
  end
end
