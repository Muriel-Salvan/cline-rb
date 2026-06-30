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

    class << self
      # Define the attributes that are already in snake case in Cline files
      #
      # @param attributes [Array<Symbol>] List of attributes already in snake case
      def cline_snake_attributes(*attributes)
        @snake_attributes ||= []
        @snake_attributes.concat(attributes)
        @snake_attributes.uniq!
      end

      # Parse a Hash object and instantiate the proper instance from it.
      #
      # @param hash [Hash] Data
      # @param args [Array] Remaining arguments to be transferred to Shale
      # @param kwargs [Hash] Remaining kwargs to be transferred to Shale
      # @return [Schema] Corresponding instance
      def of_hash(hash, *args, **kwargs)
        complete_hash_mapping
        known = hash_mapping.keys.keys
        # Separate unknown attributes.
        known_hash = {}
        extra_hash = {}
        hash.each do |key, value|
          if known.include?(key)
            known_hash[key] = value
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
      def as_hash(instance, *args, **kwargs)
        complete_hash_mapping
        hash = super
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
      def from_cline_json(json, *args, **kwargs)
        of_hash(JSON.parse(json), *args, **kwargs)
      end

      # Cast an input value to this Schema object.
      # Allow the attribute to be initialized directly using its Hash form.
      #
      # @param value [Schema, Hash, nil] The value that could be used to initialize a new instance of this attribute.
      # @return [Schema, nil] The corresponding instance, or nil if none.
      def cast(value)
        return nil if value.nil?

        # We expect the value to be either a Hash that can be used to initialize a new instance, or a new instance already initialized.
        if value.is_a?(self)
          value
        elsif value.is_a?(Hash)
          new(**value)
        else
          raise "Unable to cast #{value} into #{name}"
        end
      end

      private

      # Complete the hash mapping to include camelCase to snake_case as the defaults.
      # Do it only once.
      def complete_hash_mapping
        return if @hash_mapping_completed

        snake_attributes = @snake_attributes || []
        # Find the hash name that we expect for each attribute name
        attributes_mapping = attributes.keys.to_h do |attribute|
          [
            attribute,
            if snake_attributes.include?(attribute)
              attribute.to_s
            else
              attribute.to_s.gsub(/(?<!_)_([a-zA-Z0-9])(?!_)/) { Regexp.last_match(1).upcase }
            end
          ]
        end

        # Redefine the hash mapping for all expected attributes
        hsh do
          attributes_mapping.each do |attribute, hash_attribute|
            # Find the hash name that we expect for each attribute name
            map hash_attribute, to: attribute
          end
        end
        @hash_mapping_completed = true
      end
    end

    # Output this object as Cline JSON.
    #
    # @return [String] Cline JSON
    def to_cline_json
      JSON.dump(self.class.as_hash(self))
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
