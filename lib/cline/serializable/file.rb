module Cline
  module Serializable
    # Add features to initialize from and save an object to a file.
    #
    # Provides:
    # - `.from_file(file) -> [Object, nil]` Provides a new instance initialized from the file, or nil if no file.
    # - `.monitor_file_changes(file, on_change)` Provides a monitor to be notified on file changes.
    # - `#file -> [String]` The file from which this object was initialized.
    #
    # Requires:
    # - `#to_file(file)` Save an instance in the file
    # - `#from_file` (Optional) Initialize the instance from the file
    module File
      # @!group Internal

      # Class methods that should be made accessible to any class including our mixin
      module ClassMethods
        # Instantiate an instance of the including class from a given file.
        #
        # @param file [String] File path used to initialize the new instance
        # @param args [Array] Extra parameters to give to the instance's constructor
        # @param kwargs [Hash] Extra kwargs to give to the instance's constructor
        # @return [Object, nil] The instance, or nil if no file exists
        def from_file(file, *args, **kwargs)
          return unless ::File.exist?(file)

          instance = new(*args, **kwargs)
          instance.initialize_from_file(file)
          instance
        end

        # Monitor changes done on the file and call a callback for each update.
        #
        # @param file [String] File path to be monitored
        # @param args [Array] Extra parameters to give to the instance's constructor
        # @param on_change [#call] Block called each time there is an update.
        #   * Param instance [Object, nil] New instance with updates, or nil if no instance
        # @param monitoring_interval_secs [Float] The monitoring interval in seconds
        # @param kwargs [Hash] Extra kwargs to give to the instance's constructor
        # @yield Optional code called while monitoring is in place.
        #   If used then monitoring is stopped at the end of the block's execution.
        # @return [Utils::FileMonitor, nil] If no block has been given, return the monitor that needs to be
        #   stopped by the caller when monitoring should end.
        def monitor_file_changes(file, *args, on_change:, monitoring_interval_secs: 1, **kwargs, &)
          monitor = Utils::FileMonitor.new(
            file,
            on_change: proc do |_mtime|
              on_change.call(from_file(file, *args, **kwargs))
            end,
            monitoring_interval_secs:
          )
          monitor.start(&)
          monitor unless block_given?
        end
      end

      # Hook used when this mixin is included in a base class
      #
      # @param base [Class] The base class
      def self.included(base)
        base.extend(ClassMethods)
      end

      # @return [String] The file used for the object's initialization
      attr_reader :file

      # Initialize this instance from a file
      #
      # @param file [String] The file to be used to initialize this instance
      def initialize_from_file(file)
        @file = file
        from_file if respond_to?(:from_file, true)
      end
    end
  end
end
