require 'front_matter_parser'

module Cline
  # A skill defined in a directory
  class Skill
    # @!group Public API

    include Serializable::Dir

    # Get the skill's name
    #
    # @return [String] Skill name
    def name
      File.basename(dir)
    end

    # Get the skill's YAML front matter
    #
    # @return [Hash{Symbol => Object}, nil] The skill's front matter, or nil if none
    def yaml_front_matter
      content = skill_file_content('SKILL.md')&.content
      FrontMatterParser::Parser.new(:md).call(content).front_matter if content
    end

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(Skill) &&
        other.name == name &&
        other.files.compact == files.compact
    end

    # Get the files of this skill
    #
    # @return [Hash{String => FileContent, nil}] The files
    def files
      discover_files
      @files
    end

    # @!group Internal

    # Constructor
    def initialize
      @files = {}
      @files_discovered = false
    end

    private

    # Discover all files of this skill.
    # Remember when files were discovered to cache it.
    def discover_files
      return if @files_discovered

      Dir.glob("#{dir}/**/*", File::FNM_DOTMATCH).each do |path|
        skill_file_content(path.gsub(%r{^#{Regexp.escape(dir)}/}, '')) unless File.directory?(path)
      end
      @files_discovered = true
    end

    # Get the file content from a file path in this skill
    #
    # @param file_path [String] The file path to retrieve content from
    # @return [FileContent, nil] The file content, or nil if none
    def skill_file_content(file_path)
      @files[file_path] = FileContent.open(subpath(file_path)) unless @files.key?(file_path)
      @files[file_path]
    end
  end
end
