module Cline
  # Store a file's content, either from an existing file or just in memory for later persistence.
  class FileContent
    # @!group Public API

    # Retrieve the file's content
    #
    # @return [String] The file's content
    def content
      @content ||= File.read(file)
    end

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(FileContent) &&
        other.content == content
    end

    # @!group Internal

    include Serializable::File

    # Constructor
    #
    # @param content [String, nil] Content, or nil if the content is taken from a real file
    def initialize(content = nil)
      @content = content
    end
  end
end
