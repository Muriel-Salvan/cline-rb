require 'forwardable'

module Cline
  # Accesses all configuration of a Cline directory.
  # Wraps for example the content of ~/.cline.
  # The following properties can be used while opening a Config directory:
  # - include_project_config [Boolean] Do we include the project-specific objects as well in this
  #     configuration? Defaults to `true`.
  class Config
    extend Forwardable

    # @!group Public API

    # Get the global Cline config
    #
    # @return [Config] The global config for the current user
    def self.global
      @global ||= Config.open("#{Utils::Os.user_home_dir}/.cline")
    end

    # Get the project Cline config
    #
    # @return [Config] The project config for the current repository
    def self.project
      @project ||= Config.open('.cline')
    end

    include Serializable::Dir

    # Give access to the data getters
    def_delegators :data, *%i[global_settings logs mcp_settings sessions tasks workspaces]

    # Get skills from this config
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [OverlayHash, nil] Set of skills, including global ones and project ones if needed, or nil if non existent (see Skills).
    def skills(create: self.create)
      @skills ||= begin
        skills_layers = ([Skills.open(subpath('skills'), create:)] + [project_config&.skills]).compact
        skills_layers.empty? ? nil : OverlayHash.new(*skills_layers)
      end
    end

    # Get the data directory from this config
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [Data] The Cline data directory content
    def data(create: self.create)
      @data ||= Data.open(subpath('data'), create:)
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

    # Return a Cli instance that uses this config
    #
    # @param kwargs [Hash{Symbol => Object}] Global options (see #Cli.COMMANDS[:global])
    # @return [Cli] Cli instance that is running using this config
    def cli(**kwargs)
      Cli.new(config: dir, **kwargs)
    end

    # @!group Internal

    # Constructor
    #
    # @param include_project_config [Boolean] Do we include the project configuration in the objects read?
    def initialize(include_project_config: true)
      @include_project_config = include_project_config
    end

    # Remove caches.
    def refresh!
      @skills = nil
      @data = nil
    end

    private

    # @return [Config, nil] The additional project config if needed, or nil if none.
    def project_config
      @include_project_config && dir != Config.project&.dir ? Config.project : nil
    end
  end
end
