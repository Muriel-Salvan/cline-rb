require 'forwardable'
require 'shale'

module Cline
  module Utils
    # Provide some utility methods that are related to schema handling
    module Schema
      # @!group Internal

      # Provide a class that can be used by Shale to read and write maps of objects (dynamic keys), like this:
      # {
      #   "key1": { ... another Shale structure ... },
      #   "key2": { ... another Shale structure ... },
      #   ...
      #   "keyN": { ... another Shale structure ... }
      # }
      #
      # @param shale_type [Symbol, Class] The shale type that this class should expect for the map's values
      # @return [Class] Class that can be used in an attribute declaration
      def self.map(shale_type)
        shale_type = Shale::Type.lookup(shale_type) if shale_type.is_a?(Symbol)
        # Give a name to this class because Shale needs it to reference it in its accessors.
        # That also allows us to not redefine the same class several times.
        external_name = :"MapOf#{shale_type.to_s.gsub(':', '')}"
        unless Schema.const_defined?(external_name)
          schema_class = Class.new(Cline::Schema) do
            extend Forwardable

            # @!group Public API

            include Enumerable

            def_delegators :elements_hash, *%i[[] []= each empty? key? keys size to_hash values]

            # Constructor
            #
            # @param elements_hash [Hash{String => shale_type}] The elements to initialize the structure with
            def initialize(elements_hash = {})
              super()
              @elements_hash = elements_hash
            end

            # @!group Internal

            # @return [Hash] The elements hash taken from the extra attributes
            attr_accessor :elements_hash

            class << self
              attr_accessor :value_type, :external_name

              # Parse a Hash object and instantiate the proper instance from it.
              #
              # @param hash [Hash] Data
              # @param args [Array] Remaining arguments to be transferred to Shale
              # @param kwargs [Hash] Remaining kwargs to be transferred to Shale
              # @return [Schema] Corresponding instance
              def of_hash(hash, *args, **kwargs)
                instance = super
                # Move the extra attributes into properly constructed elements_hash
                instance.elements_hash =
                  if instance.extra_attributes.nil?
                    {}
                  else
                    instance.extra_attributes.to_h do |key, value|
                      [
                        key,
                        @value_type.of_hash(value, *args, **kwargs)
                      ]
                    end
                  end
                instance
              end

              # Get a Hash object from an instance.
              #
              # @param instance [Schema] Object to serialize to a Hash
              # @param args [Array] Remaining arguments to be transferred to Shale
              # @param kwargs [Hash] Remaining kwargs to be transferred to Shale
              # @return [Hash] Corresponding hash
              def as_hash(instance, *args, **kwargs)
                # Set the extra_attributes properly
                unless instance.elements_hash.empty?
                  instance.extra_attributes = instance.elements_hash.to_h do |key, value|
                    [
                      key,
                      @value_type.as_hash(value, *args, **kwargs)
                    ]
                  end
                end
                super
              end

              # Return the class name
              #
              # @return [String] The class name
              def to_s
                "::Cline::Utils::Schema::#{@external_name}"
              end
            end
          end
          schema_class.value_type = shale_type
          schema_class.external_name = external_name
          Schema.const_set(external_name, schema_class)
        end
        Schema.const_get(external_name)
      end
    end
  end
end
