require 'forwardable'

module Cline
  module Utils
    # Simple mixin providing an Enumerable and Set interfaces on objects initialized from
    #   a list of sub-directories.
    # Classes including this mixin should call Class.open(dir) to instantiate a new instance initialized from a directory,
    #   and implement the method object_from(dir) to return the corresponding name and object parsed from a sub-directory.
    module EnumerableDirObjects
      extend Forwardable

      # @!group Public API

      include Enumerable

      # Give a Hash interface
      def_delegators :objects_set, *%i[[] each empty? first key? keys size values]

      # Equality check
      #
      # @param other [Object] The other to check equality with
      # @return [Boolean] True if objects are equal
      def ==(other)
        other.is_a?(EnumerableDirObjects) &&
          other.size == size &&
          other.each.to_a.to_h == each.to_a.to_h
      end

      # Create a new object from this sub-directories set.
      # This also creates a new sub-directory.
      #
      # @param name [String] The object name to create (also serves as sub-directory name)
      # @return [Object] The corresponding instance that has been setup from this new sub-directory
      def new(name)
        _name, instance = object_from(File.join(dir, name), create: true)
        objects_set[name] = instance
        instance
      end

      # @!group Internal

      # Hook used when this mixin is included in a base class
      #
      # @param base [Class] The base class
      def self.included(base)
        base.include(Serializable::Dir)
      end

      # Include the mixin and configure it for a specific object class
      # This method automatically implements the required object_from method
      #
      # @param calling_class [Class] The class that is calling this method
      # @param object_class [Class] The class to instantiate for each directory
      def self.include_for(calling_class, object_class)
        calling_class.class_eval do
          include EnumerableDirObjects

          private

          # Get an object and its name from a sub-directory
          #
          # @param dir [String] The directory containing the object
          # @param create [Boolean] Should the instance be created if it does not exist?
          # @return [Array(String, Object)] Return 2 values:
          #   0. [String] The object name
          #   1. [Object] The object itself
          define_method(:object_from) do |dir, create:|
            [File.basename(dir), object_class.open(dir, create:)]
          end
        end
      end

      # Remove caches.
      def refresh!
        @objects_set = nil
      end

      private

      # Read all objects from the dir.
      # Memoize it.
      #
      # @return [Hash{String => Object}] The objects, per object name
      def objects_set
        @objects_set ||= Dir
          .glob(File.join(dir, '*'))
          .select { |path| File.directory?(path) }
          .to_h { |subdir| object_from(subdir, create: create) }
      end

      # Get an object and its name from a sub-directory
      #
      # @param dir [String] The directory containing the object
      # @param create [Boolean] Should the instance be created if it does not exist?
      # @return [Array(String, Object)] Return 2 values:
      #   0. [String] The object name
      #   1. [Object] The object itself
      def object_from(dir, create:)
        raise NotImplementedError, 'This method should be implemented by the class including this mixin.'
      end
    end
  end
end
