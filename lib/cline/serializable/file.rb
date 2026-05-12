require 'fileutils'

module Cline
  module Serializable
    # Add features to initialize from and save an object to a file.
    #
    # Provides:
    # - `.open(file) -> [Object, nil]` Provides a new instance initialized from the file, or nil if no file.
    # - `.monitor_file_changes(file, on_change)` Provides a monitor to be notified on file changes.
    # - `#file -> [String]` The file from which this object was initialized.
    module File
      # @!group Internal

      # Class methods that should be made accessible to any class including our mixin
      module ClassMethods
        # Instantiate an instance of the including class from a given file.
        #
        # @param file [String] File path used to initialize the new instance
        # @param args [Array] Extra parameters to give to the instance's constructor
        # @param default [String, nil] Default file content to be created, or nil to only read existing one
        # @param kwargs [Hash] Extra kwargs to give to the instance's constructor
        # @return [Object, nil] The instance, or nil if no file exists
        def open(file, *args, default: nil, **kwargs)
          unless ::File.exist?(file)
            return unless default

            FileUtils.mkdir_p(::File.dirname(file))
            ::File.write(file, default)
          end

          instance = new_instance(file, *args, **kwargs)
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
              on_change.call(self.open(file, *args, default: nil, **kwargs))
            end,
            monitoring_interval_secs:
          )
          monitor.start(&)
          monitor unless block_given?
        end

        # Default factory for instances.
        # This could be overriden by some classes that need to instantiate differently.
        #
        # @param _file [String] File to initialize from.
        # @param args [Array] Extra parameters to give to the instance's constructor.
        # @param kwargs [Hash] Extra kwargs to give to the instance's constructor.
        # @return [Object] A new instance.
        def new_instance(_file, *args, **kwargs)
          new(*args, **kwargs)
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
      end
    end
  end
end
