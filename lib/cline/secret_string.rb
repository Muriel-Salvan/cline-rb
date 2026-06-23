require 'secret_string'

module Cline
  # ::SecretString wrapper that allows us to use it in our Shale schemas
  class SecretString < Schema
    extend Forwardable

    # @!group Public API

    def_delegators :secret_string, *%i[to_s to_unprotected]

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(SecretString) &&
        other.to_unprotected == to_unprotected
    end

    # @!group Internal

    # Constructor
    #
    # @param unprotected_string [String] The unprotected string
    def initialize(unprotected_string)
      super()
      @secret_string = ::SecretString.new(unprotected_string)
    end

    # @return [Hash] The internal secret string
    attr_reader :secret_string

    # Output this object as a Hash.
    #
    # @return [Hash] Cline JSON
    def to_hash
      SecretString.as_hash(self)
    end

    class << self
      # Parse a Hash object and instantiate the proper instance from it.
      #
      # @param hash [Hash] Data
      # @param _args [Array] Remaining arguments to be transferred to Shale
      # @param _kwargs [Hash] Remaining kwargs to be transferred to Shale
      # @return [Schema] Corresponding instance
      def of_hash(hash, *_args, **_kwargs)
        SecretString.new(hash)
      end

      # Get a Hash object from an instance.
      #
      # @param instance [Schema] Object to serialize to a Hash
      # @param _args [Array] Remaining arguments to be transferred to Shale
      # @param _kwargs [Hash] Remaining kwargs to be transferred to Shale
      # @return [Hash] Corresponding hash
      def as_hash(instance, *_args, **_kwargs)
        instance.secret_string.to_unprotected
      end

      # Cast an input value to this Schema object.
      # Allow the attribute to be initialized directly using its Hash form.
      #
      # @param value [Schema, String, nil] The value that could be used to initialize a new instance of this attribute.
      # @return [Schema, nil] The corresponding instance, or nil if none.
      def cast(value)
        return nil if value.nil?

        # We expect the value to be a String, or a new instance already initialized.
        if value.is_a?(self)
          value
        elsif value.is_a?(String)
          new(value)
        else
          raise "Unable to cast #{value} into #{name}"
        end
      end
    end
  end
end
