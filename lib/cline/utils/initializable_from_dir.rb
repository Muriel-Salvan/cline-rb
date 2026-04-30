module Cline
  module Utils
    # Provide a class the capability to initialize itself from a directory, while keeping the directory private and outside the class' constructor.
    # This provides a class.from_dir(dir) method to the extended class.
    # The extended class should implement the method initialize_from_dir(dir).
    module InitializableFromDir
      # @!group Public API

      # Instantiate an instance of the including class from a given directory.
      #
      # @param dir [String] Directory used to initialize the new instance
      # @param args [Array] Extra parameters to give to the instance's constructor
      # @param kwargs [Hash] Extra kwargs to give to the instance's constructor
      # @return [Settings] The settings read from this directory
      def from_dir(dir, *args, **kwargs)
        instance = new(*args, **kwargs)
        instance.initialize_from_dir(dir)
        instance
      end
    end
  end
end
