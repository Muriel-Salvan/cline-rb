module ClineTest
  module Helpers
    module Skill
      # Provide a test skill
      #
      # @param name [String] The skill name
      # @param content [String, nil] The SKILL.md content, or nil if none
      # @param files [Hash{String => String}, nil] Additional files to create in the skill directory (key: relative path, value: file content)
      # @param create [Boolean] Should the data be instantiated with the create option?
      # @yield [skill] Block called with the test skill ready
      # @yieldparam [Cline::Skill] The test skill
      def with_skill(name: 'test-skill', content: nil, files: [], create: false)
        with_config(
          skills: {
            name => {
              content:,
              files:
            }
          },
          create:
        ) do |config|
          yield config.skills[name]
        end
      end
    end
  end
end
