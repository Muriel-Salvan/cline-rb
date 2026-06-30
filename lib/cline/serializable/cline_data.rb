module Cline
  # List of mixins that provide serialization/deserialization features on other objects.
  module Serializable
    # Add features to initialize from and save an object to Cline data.
    # Cline data is defined as a JSON file, relative to a base directory.
    # This mixin is intended to be included using the `.include_for(self, cline_json_file)` method.
    #
    # Provides:
    # - `.from_cline_data(base_dir) -> [Object, nil]` Provides a new instance initialized from a Cline JSON file present in a base directory.
    # - `.monitor_cline_data_changes(base_dir, on_change)` Provides a monitor to be notified on Cline data changes.
    # - `#to_cline_data(base_dir)` Save an instance in the Cline data.
    #
    # Requires:
    # - `.of_hash(hash) -> Object` The deserializer that returns an instance from a JSON object.
    # - `#to_cline_json -> String` The serializer that returns a JSON string from the instance.
    module ClineData
      # @!group Public API

      # Save the instance into the Cline data
      def save
        raise 'This instance has not been initialized from a Cline file' unless file

        FileUtils.mkdir_p(::File.dirname(file))
        ::File.write(file, to_cline_json)
      end

      # @!group Internal

      # Class methods that should be made accessible to any class including our mixin
      module ClassMethods
        # @!group Internal

        # Instantiate an instance of the including class from a base directory.
        #
        # @param base_dir [String] Base directory used to initialize the new instance
        # @param args [Array] Extra parameters to give to the instance's constructor
        # @param create [Boolean] Should data be created if it does not exist?
        # @param kwargs [Hash] Extra kwargs to give to the instance's constructor
        # @return [Object, nil] The instance, or nil if no Cline data exists
        def from_cline_data(base_dir, *args, create: false, **kwargs)
          instance = self.open(
            ::File.join(base_dir, cline_json_file(base_dir)),
            *args,
            default: create ? '{}' : nil,
            **kwargs
          )
          return unless instance

          instance.initialize_from_dir(base_dir, create:)
          instance
        end

        # Monitor changes done on the file and call a callback for each update.
        #
        # @param base_dir [String] Base directory used to initialize the new instance
        # @param args [Array] Extra parameters to give to the instance's constructor
        # @param on_change [#call] Block called each time there is an update.
        #   * Param instance [Object, nil] New instance with updates, or nil if no instance
        # @param monitoring_interval_secs [Float] The monitoring interval in seconds
        # @param kwargs [Hash] Extra kwargs to give to the instance's constructor
        # @yield Optional code called while monitoring is in place.
        #   If used then monitoring is stopped at the end of the block's execution.
        # @return [Utils::FileMonitor, nil] If no block has been given, return the monitor that needs to be
        #   stopped by the caller when monitoring should end.
        def monitor_cline_data_changes(base_dir, *args, on_change:, monitoring_interval_secs: 1, **kwargs, &)
          monitor_updates(
            ::File.join(base_dir, cline_json_file(base_dir)),
            *args,
            on_change: proc do |instance|
              instance.initialize_from_dir(base_dir, create: false)
              on_change.call(instance)
            end,
            monitoring_interval_secs:,
            **kwargs,
            &
          )
        end

        # Default factory for instances.
        # This could be overriden by some classes that need to instantiate differently.
        #
        # @param file [String] File to initialize from.
        # @param args [Array] Extra parameters to give to the instance's constructor.
        # @param kwargs [Hash] Extra kwargs to give to the instance's constructor.
        # @return [Object] A new instance.
        def new_instance(file, *args, **kwargs)
          # TODO: Implement a retry mechanism if JSON is not parseable as it can be due to the file being written concurrently.
          of_hash(JSON.parse(Utils::File.safe_read(file)), *args, **kwargs)
        end

        private

        # Get the relative JSON file path from the base directory
        #
        # @param base_dir [String] The base directory
        # @return [String] The relative JSON file path
        def cline_json_file(base_dir)
          cline_json_file_def.is_a?(Proc) ? cline_json_file_def.call(base_dir) : cline_json_file_def
        end
      end

      # Include the mixin and configure it with the JSON file path
      #
      # @param calling_class [Class] The class that is calling this method.
      # @param cline_json_file_def [String, #call] The definition of the relative JSON file path to use. Can be one of:
      #   - [String] The static relative JSON file path to be used.
      #   - [#call] A proc that can devise dynamically the relative file path from the base directory:
      #     - Param base_dir [String] The base directory from which the JSON file is searched.
      #     - Return [String] The corresponding relative JSON file path from base_dir.
      def self.include_for(calling_class, cline_json_file_def)
        calling_class.class_eval do
          include Dir
          include File
          include ClineData

          class << self
            # @return [String] The relative JSON file path
            attr_accessor :cline_json_file_def
          end
        end
        calling_class.cline_json_file_def = cline_json_file_def
      end

      # Hook used when this mixin is included in a base class
      #
      # @param base [Class] The base class
      def self.included(base)
        base.extend(ClassMethods)
      end
    end
  end
end
