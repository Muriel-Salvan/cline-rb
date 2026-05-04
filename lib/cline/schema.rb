require 'json'
require 'shale'

module Cline
  # Base class for any Cline domain object that defines some attributes that are serializable in JSON.
  # Handle the following features:
  # * Provide Shale attributes interface.
  # * Automatically transforms Cline camelCase naming.
  # * Keep track of extra attributes to serialize them back if needed.
  class Schema < Shale::Mapper
    # @!group Internal

    # @return [Hash] Store all extra values from a JSON parse
    attr_accessor :extra_attributes

    # Parse a Hash object and instantiate the proper instance from it.
    #
    # @param hash [Hash] Data
    # @param args [Array] Remaining arguments to be transferred to Shale
    # @param kwargs [Hash] Remaining kwargs to be transferred to Shale
    # @return [Schema] Corresponding instance
    def self.of_hash(hash, *args, **kwargs)
      known = attributes.keys.map(&:to_s)
      # Only transform the keys that are known. Don't touch others.
      known_hash = {}
      extra_hash = {}
      hash.each do |key, value|
        transformed_key = key.gsub(/([a-z0-9])([A-Z])/, '\1_\2').downcase
        if known.include?(transformed_key)
          known_hash[transformed_key] = value
        else
          extra_hash[key] = value
        end
      end
      # Give Shale the data it knows about, without extra attributes
      instance = super(known_hash, *args, **kwargs)
      instance.extra_attributes = extra_hash unless extra_hash.empty?
      instance
    end

    # Get a Hash object from an instance.
    #
    # @param instance [Schema] Object to serialize to a Hash
    # @param args [Array] Remaining arguments to be transferred to Shale
    # @param kwargs [Hash] Remaining kwargs to be transferred to Shale
    # @return [Hash] Corresponding hash
    def self.as_hash(instance, *args, **kwargs)
      hash = super.transform_keys { |key| key.gsub(/(?<!_)_([a-zA-Z0-9])(?!_)/) { Regexp.last_match(1).upcase } }
      hash.merge!(instance.extra_attributes) if instance.extra_attributes
      hash
    end

    # Parse a Cline JSON object and instantiate the proper instance from it.
    # Handle the following features:
    # * Cline camelCase naming.
    # * Keep track of extra attributes to serialize them back if needed.
    #
    # @param json [String] JSON data
    # @param args [Array] Remaining arguments to be transferred to Shale
    # @param kwargs [Hash] Remaining kwargs to be transferred to Shale
    # @return [Object] Corresponding instance
    def self.from_cline_json(json, *args, **kwargs)
      of_hash(JSON.parse(json), *args, **kwargs)
    end

    # Output this object as Cline JSON.
    #
    # @return [String] Cline JSON
    def to_cline_json
      self.class.as_hash(self).to_json
    end

    # Output this object as a Hash.
    #
    # @return [Hash] Cline JSON
    def to_hash
      hash = self.class.attributes.to_h do |attribute|
        value = send(attribute.to_sym)
        [
          attribute,
          value.respond_to?(:to_hash) ? value.to_hash : value
        ]
      end
      hash.merge!(extra_attributes:) if extra_attributes
      hash
    end

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(Schema) &&
        other.to_hash == to_hash
    end
  end
end
