require 'json'
require 'forwardable'

module Cline
  # Access cached Cline models
  class Models
    extend Forwardable

    # @!group Public API

    Serializable::ClineData.include_for(self, 'cache/cline_models.json')
    include Enumerable

    # Delegates hash methods to the internal models map
    def_delegators :models, *%i[[] each empty? first key? keys size values]

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(Models) &&
        other.models == @models
    end

    # @!group Internal

    # Constructor
    #
    # @param models [Hash{String => Model}] Hash of models indexed by model ID
    def initialize(models)
      @models = models
    end

    # Parse a Cline JSON object and instantiate the proper instance from it.
    # Handle the following features:
    # * Cline camelCase naming.
    # * Keep track of extra attributes to serialize them back if needed.
    #
    # @param json [String] JSON data
    # @return [Object] Corresponding instance
    def self.from_cline_json(json)
      Models.new(JSON.parse(json).to_h { |model_id, model_data| [model_id, Model.of_hash(model_data)] })
    end

    # Output this object as Cline JSON.
    #
    # @return [String] Cline JSON
    def to_cline_json
      @models.transform_values { |model| Model.as_hash(model) }.to_json
    end

    protected

    # @return [Array<Model>] List of models
    attr_reader :models
  end
end
