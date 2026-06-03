require 'front_matter_parser'
require 'yaml'

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

    # Save the skill files
    def save
      raise 'This instance has not been initialized from a Skill directory' unless dir

      # First create/update all known files
      files.each do |file_path, file_content|
        next unless file_content

        file_full_path = File.join(dir, file_path)
        FileUtils.mkdir_p(File.dirname(file_full_path))
        File.write(file_full_path, file_content.content)
      end
      # Then delete any file that is not known
      each_file do |file_path|
        File.unlink(File.join(dir, file_path)) unless files[file_path]
      end
    end

    # Enable the skill
    def enable
      return unless yaml_front_matter
      return unless yaml_front_matter['disabled']

      modify_skill_front_matter do |front_matter|
        front_matter.except('disabled')
      end
    end

    # Disable the skill
    def disable
      return unless yaml_front_matter
      return if yaml_front_matter['disabled']

      modify_skill_front_matter do |front_matter|
        front_matter.merge('disabled' => true)
      end
    end

    # @!group Internal

    # Constructor
    def initialize
      @files = {}
      @files_discovered = false
    end

    private

    # Loop over all existing relative file paths inside our directory
    #
    # @yield The code to execute for each file found
    # @yieldparam file_path [String] The relative file path
    def each_file
      dir_regexp = %r{^#{Regexp.escape(dir)}/}
      Dir.glob("#{dir}/**/*", File::FNM_DOTMATCH).each do |path|
        yield(path.gsub(dir_regexp, '')) unless File.directory?(path)
      end
    end

    # Discover all files of this skill.
    # Remember when files were discovered to cache it.
    def discover_files
      return if @files_discovered

      each_file do |file_path|
        skill_file_content(file_path)
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

    # Modify the content of a skill file's front matter
    #
    # @yield [front_matter] The block to execute to modify the front matter
    # @yieldparam front_matter [Hash] The parsed front matter hash
    # @yieldreturn [Hash] The modified front matter hash
    def modify_skill_front_matter
      content = skill_file_content('SKILL.md').content
      new_front_matter = yield(YAML.safe_load(content.match(/^---\n(.+?)\n---/m)[1]) || {})
      content.replace(
        content.gsub(
          /^---\n(.+?)\n---/m,
          "---\n#{YAML.dump(new_front_matter).gsub(/\A---\n/, '') unless new_front_matter.empty?}---"
        )
      )
    end
  end
end
