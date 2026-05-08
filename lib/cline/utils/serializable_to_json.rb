module Cline
  module Utils
    # Provide a class the capability serialize and deserialize itself into a JSON file, relative to a base directory.
    # This provides:
    # * Class method json_from_base_dir(base_dir) to instantiate a new instance from a file present in this base directory.
    # * Instance method json_to_base_dir(base_dir) to save the instance into a JSON file in the base directory.
    # The class including this mixin should implement the following methods:
    # * Class method json_file_path to return the relative JSON file path to be used.
    # * Class method from_cline_json(json) to return an instance based on some JSON string content.
    # * Instance method to_cline_json to return a JSON string serializing the instance.
    module SerializableToJson
      # @!group Internal

      # Hook used when this mixin is included in a base class
      #
      # @param base [Class] The base class
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Include the mixin and configure it with the JSON file path
      #
      # @param calling_class [Class] The class that is calling this method
      # @param json_file_path [String] The relative JSON file path to use
      def self.include_for(calling_class, json_file_path)
        calling_class.class_eval do
          include SerializableToJson

          class << self
            # @return [String] The relative JSON file path
            attr_accessor :json_file_path
          end
        end
        calling_class.json_file_path = json_file_path
      end

      # Class methods that should be made accessible to any class including our mixin
      module ClassMethods
        # Instantiate an instance of the including class from a base directory.
        #
        # @param base_dir [String] Base directory used to initialize the new instance
        # @param args [Array] Extra parameters to give to the from_cline_json constructor
        # @param kwargs [Hash] Extra kwargs to give to the from_cline_json constructor
        # @return [Object, nil] The instance, or nil if no JSON file exists
        def json_from_base_dir(base_dir, *args, **kwargs)
          json_file = File.join(base_dir, json_file_path)
          File.exist?(json_file) ? from_cline_json(safe_read(json_file), *args, **kwargs) : nil
        end

        # Monitor changes done on the JSON file and call a callback for each update.
        #
        # @param base_dir [String] Base directory used to initialize the new instance
        # @param args [Array] Extra parameters to give to the from_cline_json constructor
        # @param on_change [#call] Block called each time there is an update.
        #   * Param instance [Object, nil] New instance with updates, or nil if no instance
        # @param monitoring_interval_secs [Float] The monitoring interval in seconds
        # @param kwargs [Hash] Extra kwargs to give to the from_cline_json constructor
        # @yield Optional code called while monitoring is in place.
        #   If used then monitoring is stopped at the end of the block's execution.
        # @return [FileMonitor, nil] If no block has been given, return the monitor that needs to be
        #   stopped by the caller when monitoring should end.
        def monitor_changes(base_dir, *args, on_change:, monitoring_interval_secs: 1, **kwargs, &)
          monitor = FileMonitor.new(
            File.join(base_dir, json_file_path),
            on_change: proc do |_mtime|
              on_change.call(json_from_base_dir(base_dir, *args, **kwargs))
            end,
            monitoring_interval_secs:
          )
          monitor.start(&)
          monitor unless block_given?
        end

        # Return the file path to serialize the instance in a JSON file.
        # The path is relative to the base dir.
        #
        # @return [String] The relative JSON file path
        def json_file_path
          raise NotImplementedError, 'This method should be implemented by sub-classes'
        end

        private

        # Try to read a file with retries in case other processes are using it.
        #
        # Parameters::
        # * *file* (String): Path to read
        # * *max_retries* (Integer): Number of retries in case of concurrent access [default: 3]
        # Result::
        # * String: The file content
        def safe_read(file, max_retries: 3)
          retries = 0
          file_content = nil
          begin
            file_content = File.read(file)
          rescue Errno::EACCES, Errno::EAGAIN
            # Could be that the file is being written at the same time.
            # Just try again.
            retries += 1
            raise if retries > max_retries

            sleep(0.05 * retries)
            retry
          end
          file_content
        end
      end

      # Save the instance into a JSON file in the base directory
      #
      # @param base_dir [String] Base directory in which the instance should be saved
      def json_to_base_dir(base_dir)
        json_file = File.join(base_dir, self.class.json_file_path)
        FileUtils.mkdir_p(File.dirname(json_file))
        File.write(json_file, to_cline_json)
      end
    end
  end
end
