module Cline
  # Base class for schemas whose data may not respect the expected types on deserialization.
  # This is typically the case for attributes filled by an LLM, whose types are not guaranteed
  # by the Cline CLI (for example a String given where an Array is expected).
  #
  # Contrary to {Schema}, deserialization does not raise exceptions for such wrong data:
  # a warning is emitted, every attribute that can be deserialized properly is set on the instance,
  # and the other attributes are stored in {#wrong_attributes}, keyed by their attribute name.
  #
  # @example
  #   input = Cline::SessionMessage::MessageContent::ToolUseInput.of_hash(
  #     'question' => 'Continue?',
  #     'files' => 'not-an-array'
  #   )
  #   input.question          #=> 'Continue?'
  #   input.files             #=> nil
  #   input.wrong_attributes  #=> { files: 'not-an-array' }
  class LenientSchema < Schema
    extend Utils::Logger

    # @!group Public API

    # The attributes that could not be deserialized, keyed by their attribute name, with their raw value.
    # Only set when at least one attribute could not be deserialized.
    # When the whole value is not a Hash, it is stored under the '_raw' key.
    #
    # @return [Hash{Symbol => Object}, nil] The wrong attributes, or nil if deserialization succeeded
    attr_accessor :wrong_attributes

    class << self
      # @!group Internal

      # Cast an input value to this Schema object.
      # Any value that cannot be cast is turned into an empty instance with {#wrong_attributes} set,
      # instead of raising an exception.
      #
      # @param value [Schema, Hash, nil] The value that could be used to initialize a new instance of this attribute
      # @return [Schema, nil] The corresponding instance, or nil if none
      def cast(value)
        super
      rescue StandardError => e
        # TODO: Make this a warn message when logger will be implemented properly
        log_debug "!!! Cline: Unable to cast a #{value.class} into a #{name} (#{e.class}: #{e.message}). Raw value: #{value.to_s[0, 256]}"
        instance = new
        instance.wrong_attributes = { '_raw' => value.to_s }
        instance
      end

      # Parse a Hash object and instantiate the proper instance from it.
      # Instead of raising an exception when an attribute cannot be deserialized
      # (wrong type, wrong structure...), this attribute is left unset and its raw value
      # is stored in {#wrong_attributes}, while a warning is emitted.
      # Attributes that can be deserialized properly are still set on the instance.
      #
      # @param hash [Hash] Data
      # @param args [Array] Remaining arguments to be transferred to Shale
      # @param kwargs [Hash] Remaining kwargs to be transferred to Shale
      # @return [LenientSchema] Corresponding instance
      def of_hash(hash, *args, **kwargs)
        complete_hash_mapping
        instance = new
        unless hash.is_a?(Hash)
          # TODO: Make this a warn message when logger will be implemented properly
          log_debug "Cline: Unable to deserialize a #{name} from a #{hash.class}. Raw value: #{hash.to_s[0, 256]}"
          instance.wrong_attributes = { '_raw' => hash.to_s }
          return instance
        end
        mappings = hash_mapping.keys
        wrong_attributes = {}
        hash.each do |key, value|
          mapping = mappings[key]
          if mapping.nil?
            # Keep unknown attributes for round-trip fidelity, as Schema does
            (instance.extra_attributes ||= {})[key] = value
            next
          end
          begin
            set_attribute_from_hash(instance, mapping, value, *args, **kwargs)
          rescue StandardError => e
            # TODO: Make this a warn message when logger will be implemented properly
            log_debug "Cline: Unable to deserialize attribute #{key.inspect} of #{name} (#{e.class}: #{e.message}). Raw value: #{value.to_s[0, 256]}"
            wrong_attributes[mapping.attribute] = value
          end
        end
        instance.wrong_attributes = wrong_attributes unless wrong_attributes.empty?
        instance
      end

      private

      # Set one attribute of an instance from its Hash value, mirroring Shale's own of_hash logic.
      #
      # @param instance [LenientSchema] The instance to set the attribute on
      # @param mapping [Shale::Mapping::Descriptor::Dict] The hash mapping of the attribute
      # @param value [Object] The raw value to deserialize
      # @param args [Array] Remaining arguments to be transferred to Shale
      # @param kwargs [Hash] Remaining kwargs to be transferred to Shale
      # @return [void]
      def set_attribute_from_hash(instance, mapping, value, *args, **kwargs)
        attribute = attributes[mapping.attribute]
        check_scalar_value!(attribute, value)
        casted_value =
          if value.nil?
            nil
          elsif attribute.collection?
            (value.is_a?(Array) ? value : [value]).map do |element|
              element.nil? ? nil : attribute.type.cast(attribute.type.of_hash(element, *args, **kwargs))
            end
          else
            attribute.type.cast(attribute.type.of_hash(value, *args, **kwargs))
          end
        instance.send(attribute.setter, casted_value)
      end
    end
  end
end
