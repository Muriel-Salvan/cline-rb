require 'fileutils'

module Cline
  module Serializable
    # Add features to initialize from and save an object to a directory.
    #
    # Provides:
    # - `.open(dir) -> [Object, nil]` Provides a new instance initialized from the directory, or nil if no directory.
    # - `#dir -> [String]` The directory from which this object was initialized.
    # - `#subdir(path) -> [String]` Provide a subdirectory path from the directory the object was initialized from.
    #
    # Requires:
    # - `#to_dir(dir)` Save an instance in a directory
    # - `#from_dir` (Optional) Initialize the instance from the directory
    module Dir
      # Class methods that should be made accessible to any class including our mixin
      module ClassMethods
        # @!group Public API

        # Instantiate an instance of the including class from a given directory.
        #
        # @param dir [String] Directory used to initialize the new instance
        # @param args [Array] Extra parameters to give to the instance's constructor
        # @param create [Boolean] Should the directory be created if it does not exist?
        # @param kwargs [Hash] Extra kwargs to give to the instance's constructor
        # @return [Object, nil] The instance initialized from this directory, or nil if none
        def open(dir, *args, create: false, **kwargs)
          unless ::File.exist?(dir) && ::File.directory?(dir)
            return unless create

            FileUtils.mkdir_p dir
          end
          instance = new_instance(dir, *args, **kwargs)
          instance.initialize_from_dir(dir, create:)
          instance
        end

        # @!group Internal

        # Default factory for instances.
        # This could be overriden by some classes that need to instantiate differently.
        #
        # @param _dir [String] The directory to create the instance for.
        # @param args [Array] Extra parameters to give to the instance's constructor.
        # @param kwargs [Hash] Extra kwargs to give to the instance's constructor.
        # @return [Object] A new instance.
        def new_instance(_dir, *args, **kwargs)
          new(*args, **kwargs)
        end
      end

      # @!group Internal

      # Hook used when this mixin is included in a base class
      #
      # @param base [Class] The base class
      def self.included(base)
        base.extend(ClassMethods)
      end

      # @return [String] The directory used for the object's initialization
      attr_reader :dir

      # @return [Boolean] Should data be created if it does not exist?
      attr_reader :create

      # Initialize this instance from a directory
      #
      # @param dir [String] The directory to be used to initialize this instance
      # @param create [Boolean] Should data be created if it does not exist?
      def initialize_from_dir(dir, create:)
        @dir = dir
        @create = create
        from_dir if respond_to?(:from_dir, true)
      end

      # Return the path to a sub-directory of our instance directory
      #
      # @param path [String] The relative sub-directory path
      # @return [String] The full path to the sub-directory
      def subdir(path)
        ::File.join(dir, path)
      end
    end
  end
end
