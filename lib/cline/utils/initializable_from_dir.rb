module Cline
  module Utils
    # Provide a class the capability to initialize itself from a directory, while keeping the directory private and outside the class' constructor.
    # This provides a class.from_dir(dir) method to the extended class.
    # Then sub-classes can use the instance method subdir to reach to sub-directories of the instance.
    # The extended class should implement the method initialize_from_dir(dir).
    module InitializableFromDir
      # Class methods that should be made accessible to any class including our mixin
      module ClassMethods
        # @!group Public API

        # Instantiate an instance of the including class from a given directory.
        #
        # @param dir [String] Directory used to initialize the new instance
        # @param args [Array] Extra parameters to give to the instance's constructor
        # @param kwargs [Hash] Extra kwargs to give to the instance's constructor
        # @return [Object, nil] The instance initialized from this directory, or nil if none
        def from_dir(dir, *args, **kwargs)
          return unless File.exist?(dir) && File.directory?(dir)

          instance = new(*args, **kwargs)
          instance.initialize_from_dir(dir)
          instance
        end

        # @!endgroup
      end

      # @!group Internal

      # Hook used when this mixin is included in a base class
      #
      # @param base [Class] The base class
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Initialize this instance from a directory
      #
      # @param dir [String] The directory to be used to initialize this instance
      def initialize_from_dir(dir)
        @dir = dir
      end

      # Return the path to a sub-directory of our instance directory
      #
      # @param path [String] The relative sub-directory path
      # @return [String] The full path to the sub-directory
      def subdir(path)
        File.join(@dir, path)
      end
    end
  end
end
