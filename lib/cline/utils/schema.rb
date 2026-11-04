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

            def_delegators :elements_hash, *%i[[] each empty? key? keys size to_hash values]

            # Constructor
            #
            # @param elements_hash [Hash{String => shale_type}] The elements to initialize the structure with
            def initialize(elements_hash = {})
              super()
              @elements_hash = elements_hash
            end

            # Set a key and its corresponding value.
            # Handle potential casting for the value.
            #
            # @param key [Object] The key to set.
            # @param value [Object] The value to set.
            def []=(key, value)
              elements_hash[key] = self.class.value_type.cast(value)
            end

            # Equality check
            #
            # @param other [Object] The other to check equality with
            # @return [Boolean] True if objects are equal
            def ==(other)
              other.is_a?(self.class) &&
                other.elements_hash == elements_hash
            end

            # @!group Internal

            # @return [Hash] The elements hash taken from the extra attributes
            attr_accessor :elements_hash

            class << self
              attr_accessor :value_type, :external_name

              # Hook called when a subclass inherits our class
              #
              # @param subclass [Class] The inheriting class
              def inherited(subclass)
                super
                subclass.value_type = value_type
              end

              # Check if a raw value can be deserialized by this map.
              #
              # @param raw_value [Object] The raw value to check
              # @return [Boolean] true if this map can deserialize this value
              def accepts_value?(raw_value)
                raw_value.is_a?(self) || raw_value.is_a?(Hash)
              end

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

              # Cast an input value to this Schema object.
              # Allow the attribute to be initialized directly using its Hash form.
              #
              # @param value [Schema, Hash, nil] The value that could be used to initialize a new instance of this attribute.
              # @return [Schema, nil] The corresponding instance, or nil if none.
              def cast(value)
                return nil if value.nil?

                # We expect the value to be a Hash of values that can themselves be cast using the Shale type, or a new instance already initialized.
                if value.is_a?(self)
                  value
                elsif value.is_a?(Hash)
                  new(value.to_h { |k, v| [k, value_type.cast(v)] })
                else
                  raise "Unable to cast #{value} into #{name}"
                end
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

      # Provide a class that can be used by Shale to read and write arrays of objects, like this:
      # [
      #   { ... another Shale structure ... },
      #   { ... another Shale structure ... },
      #   ...
      #   { ... another Shale structure ... }
      # ]
      # We don't use the native Shale collection's feature as it does not support type casting at element,
      #   and so prevents initialization like that: my_object.my_collection = [{ attr: 1 }, { attr: 2 }].
      #
      # @param shale_type [Symbol, Class] The shale type that this class should expect for the array's values
      # @return [Class] Class that can be used in an attribute declaration
      def self.collection(shale_type)
        shale_type = Shale::Type.lookup(shale_type) if shale_type.is_a?(Symbol)
        # Give a name to this class because Shale needs it to reference it in its accessors.
        # That also allows us to not redefine the same class several times.
        external_name = :"CollectionOf#{shale_type.to_s.gsub(':', '')}"
        unless Schema.const_defined?(external_name)
          schema_class = Class.new(Cline::Schema) do
            extend Forwardable

            # @!group Public API

            include Enumerable

            def_delegators :elements, *%i[[] each empty? last size]

            # Constructor
            #
            # @param elements [Array<shale_type>] The elements to initialize the structure with
            def initialize(elements = [])
              super()
              @elements = elements
            end

            # Set a value at a given index.
            # Handle potential casting for the value.
            #
            # @param idx [Integer] The integer to set.
            # @param value [Object] The value to set.
            def []=(idx, value)
              elements[idx] = self.class.value_type.cast(value)
            end

            # Append a value.
            # Handle potential casting for the value.
            #
            # @param value [Object] The value to set.
            def <<(value)
              elements << self.class.value_type.cast(value)
            end

            # Equality check
            #
            # @param other [Object] The other to check equality with
            # @return [Boolean] True if objects are equal
            def ==(other)
              other.is_a?(self.class) &&
                other.elements == elements
            end

            # @!group Internal

            # Output this object as a Ruby object that can be JSON-serialized.
            #
            # @return [Object] Ruby object ready for JSON
            def to_hash
              elements.map { |element| element.respond_to?(:to_hash) ? element.to_hash : element }
            end

            # @return [Hash] The elements array
            attr_accessor :elements

            class << self
              attr_accessor :value_type, :external_name

              # Hook called when a subclass inherits our class
              #
              # @param subclass [Class] The inheriting class
              def inherited(subclass)
                super
                subclass.value_type = value_type
              end

              # Check if a raw value can be deserialized by this collection.
              #
              # @param raw_value [Object] The raw value to check
              # @return [Boolean] true if this collection can deserialize this value
              def accepts_value?(raw_value)
                raw_value.is_a?(self) || raw_value.is_a?(Array)
              end

              # Parse a Ruby object and instantiate the proper instance from it.
              #
              # @param hash [Object] Data
              # @param args [Array] Remaining arguments to be transferred to Shale
              # @param kwargs [Hash] Remaining kwargs to be transferred to Shale
              # @return [Schema] Corresponding instance
              def of_hash(hash, *args, **kwargs)
                new(hash.map { |element| value_type.of_hash(element, *args, **kwargs) })
              end

              # Get a Ruby object from an instance.
              #
              # @param instance [Schema] Object to serialize to a Hash
              # @param args [Array] Remaining arguments to be transferred to Shale
              # @param kwargs [Hash] Remaining kwargs to be transferred to Shale
              # @return [Object] Corresponding Ruby object
              def as_hash(instance, *args, **kwargs)
                instance.elements.map { |element| value_type.as_hash(element, *args, **kwargs) }
              end

              # Cast an input value to this Schema object.
              # Allow the attribute to be initialized directly using its Array form.
              #
              # @param value [Schema, Array, nil] The value that could be used to initialize a new instance of this attribute.
              # @return [Schema, nil] The corresponding instance, or nil if none.
              def cast(value)
                return nil if value.nil?

                # We expect the value to be a Array of values that can themselves be cast using the Shale type, or a new instance already initialized.
                if value.is_a?(self)
                  value
                elsif value.is_a?(Array)
                  new(value.map { |element| value_type.cast(element) })
                else
                  raise "Unable to cast #{value} into #{name}"
                end
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

      # Provide a class that can be used by Shale for attributes that can be of several types, like this:
      #   "content": "Some text"                  # A String
      #   "content": [{ "query": "ls" }, ...]     # An Array of structures
      # The first type accepting a value is used to deserialize / serialize it.
      #
      # @param shale_types [Array<Symbol, Class>] The Shale types this attribute can be (at least 2)
      # @return [Class] Class that can be used in an attribute declaration
      def self.union(*shale_types)
        Union.of(*shale_types)
      end

      # Handle union types: attributes that can be of several types.
      # Used by {Cline::Utils::Schema.union}.
      class Union
        # @!group Internal

        # Ruby classes that can be deserialized by each scalar Shale type.
        # Shale types not listed here are considered to accept any value.
        SCALAR_VALUE_CLASSES = {
          Shale::Type::String => String,
          Shale::Type::Integer => Integer,
          Shale::Type::Float => Float,
          Shale::Type::Boolean => [TrueClass, FalseClass],
          Shale::Type::Date => Date,
          Shale::Type::Time => Time,
          Shale::Type::Decimal => BigDecimal
        }.freeze

        class << self
          # Build (or retrieve) the type class for a union of the given types.
          #
          # @param shale_types [Array<Symbol, Class>] The Shale types this union can be (at least 2)
          # @return [Class] Class that can be used in an attribute declaration
          def of(*shale_types)
            raise ArgumentError, "A union type needs at least 2 types, got #{shale_types.size}" if shale_types.size < 2

            shale_types = shale_types.map { |shale_type| shale_type.is_a?(Symbol) ? Shale::Type.lookup(shale_type) : shale_type }
            # Give a name to this class because Shale needs it to reference it in its accessors.
            # That also allows us to not redefine the same class several times.
            external_name = :"UnionOf#{shale_types.map { |shale_type| shale_type.to_s.gsub(':', '') }.join('Or')}"
            unless Cline::Utils::Schema.const_defined?(external_name)
              union_class = new_union_class
              union_class.union_types = shale_types
              union_class.external_name = external_name
              Cline::Utils::Schema.const_set(external_name, union_class)
            end
            Cline::Utils::Schema.const_get(external_name)
          end

          # Check if a raw value can be deserialized by a given Shale type.
          # Shale types that don't handle accepted values are considered as scalar types.
          #
          # @param shale_type [Class] The Shale type to check
          # @param raw_value [Object] The raw value to check
          # @return [Boolean] true if the Shale type can deserialize this value
          def accepts_value?(shale_type, raw_value)
            if shale_type.respond_to?(:accepts_value?)
              shale_type.accepts_value?(raw_value)
            else
              raw_value.is_a?(SCALAR_VALUE_CLASSES.fetch(shale_type, Object))
            end
          end

          private

          # Create the class implementing a union type.
          #
          # @return [Class] The new union type class
          def new_union_class
            Class.new(Cline::Schema) do
              class << self
                attr_accessor :union_types, :external_name

                # Check if a raw value can be deserialized by one of this union's types.
                #
                # @param raw_value [Object] The raw value to check
                # @return [Boolean] true if one of this union's types accepts this value
                def accepts_value?(raw_value)
                  raw_value.is_a?(self) ||
                    union_types.any? { |union_type| Cline::Utils::Schema::Union.accepts_value?(union_type, raw_value) }
                end

                # Parse a value and instantiate the proper instance from it.
                #
                # @param value [Object] Data
                # @param args [Array] Remaining arguments to be transferred to Shale
                # @param kwargs [Hash] Remaining kwargs to be transferred to Shale
                # @return [Object, nil] Corresponding instance, or nil if value is nil
                def of_hash(value, *args, **kwargs)
                  return nil if value.nil?

                  union_type_for(value).of_hash(value, *args, **kwargs)
                end

                # Get a Ruby object from an instance.
                #
                # @param value [Object] Object to serialize
                # @param args [Array] Remaining arguments to be transferred to Shale
                # @param kwargs [Hash] Remaining kwargs to be transferred to Shale
                # @return [Object, nil] Corresponding Ruby object, or nil if value is nil
                def as_hash(value, *args, **kwargs)
                  return nil if value.nil?

                  union_type_for(value).as_hash(value, *args, **kwargs)
                end

                # Cast an input value to the type matching it.
                #
                # @param value [Object, nil] The value to cast
                # @return [Object, nil] The corresponding instance, or nil if none
                def cast(value)
                  return nil if value.nil?

                  union_type_for(value).cast(value)
                end

                # Return the class name
                #
                # @return [String] The class name
                def to_s
                  "::Cline::Utils::Schema::#{@external_name}"
                end

                private

                # Get the type that can deserialize / serialize a given value.
                #
                # @param value [Object] The value to find the type of
                # @return [Class] The corresponding type
                def union_type_for(value)
                  union_types.find { |union_type| Cline::Utils::Schema::Union.accepts_value?(union_type, value) } ||
                    raise("Unable to cast a #{value.class} into #{name}")
                end
              end
            end
          end
        end
      end
    end
  end
end
