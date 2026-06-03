require 'forwardable'

module Cline
  # Class merging several Hash-like objects to give a uniform view of them through another Hash-like interface.
  # This is used to provide unifide representations of objects present in both project and global configs.
  # Write operations are performed on the top layer only.
  class OverlayHash
    extend Forwardable

    # @!group Public API

    include Enumerable

    # Loop over all elements.
    #
    # @yield Optional code called for each key and value.
    # @yieldparam key [Object] The key being iterated on.
    # @yieldparam value [Object] The value being iterated on.
    # @return [Enumerator] The enumerator if no block is given.
    def each
      return enum_for(:each) unless block_given?

      seen = {}
      @layers.each do |layer|
        layer.each do |key, value|
          next if seen.key?(key)

          seen[key] = true
          yield key, value
        end
      end
    end

    # Retrieve the value for a given key from the first layer that contains it.
    #
    # @param key [Object] The key to look up.
    # @return [Object, nil] The value associated with the key, or +nil+ if not found in any layer.
    def [](key)
      @layers.each do |layer|
        return layer[key] if layer.key?(key)
      end
      nil
    end

    # Check whether the given key exists in any layer.
    #
    # @param key [Object] The key to check for.
    # @return [Boolean] +true+ if the key is present in at least one layer, +false+ otherwise.
    def key?(key)
      @layers.any? { |layer| layer.key?(key) }
    end

    # Return all unique keys across all layers, in priority order.
    #
    # @return [Array<Object>] The list of unique keys.
    def keys
      map { |k, _v| k }
    end

    # Return all values across all layers, in priority order.
    #
    # @return [Array<Object>] The list of values corresponding to the unique keys.
    def values
      map { |_k, v| v }
    end

    # Return the number of unique keys across all layers.
    #
    # @return [Integer] The total count of unique keys.
    def size
      keys.size
    end

    # Check whether the overlay hash contains any entries.
    #
    # @return [Boolean] +true+ if there are no entries across all layers, +false+ otherwise.
    def empty?
      none?
    end

    # Convert the overlay hash into a plain Ruby Hash.
    #
    # @return [Hash] A new hash containing all unique key-value pairs in priority order.
    def to_h
      each_with_object({}) do |(key, value), h|
        h[key] = value
      end
    end

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(OverlayHash) &&
        other.layers == layers
    end

    # Delegate all write and singleton operations to the first layer
    def_delegators :first_layer, *%i[dir new]

    # @!group Internal

    # Constructor
    #
    # @params layers [Array] List of Hash-like objects that should be served.
    #   In case of conflicting keys, the first ones in the list get priority.
    #   Write operations are performed on the first one only.
    def initialize(*layers)
      @layers = layers
    end

    protected

    # @return [Array<Object>] The list of layers
    attr_reader :layers

    private

    # @return [Object] First layer
    def first_layer
      @layers.first
    end
  end
end
