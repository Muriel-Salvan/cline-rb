describe Cline::Skill, '#yaml_front_matter' do
  it 'returns nil when SKILL.md does not exist' do
    with_skill(content: nil) do |skill|
      expect(skill.yaml_front_matter).to be_nil
    end
  end

  it 'returns empty hash when SKILL.md is empty' do
    with_skill(content: '') do |skill|
      expect(skill.yaml_front_matter).to eq({})
    end
  end

  it 'returns empty hash when SKILL.md exists without YAML front matter' do
    with_skill(
      content: <<~EO_SKILL
        # My Skill

        Some content without front matter.
      EO_SKILL
    ) do |skill|
      expect(skill.yaml_front_matter).to eq({})
    end
  end

  it 'returns the YAML front matter when SKILL.md has it' do
    with_skill(
      content: <<~EO_SKILL
        ---
        title: My Skill
        description: A test skill
        ---

        # My Skill

        Some content.
      EO_SKILL
    ) do |skill|
      expect(skill.yaml_front_matter).to eq(
        {
          'title' => 'My Skill',
          'description' => 'A test skill'
        }
      )
    end
  end

  it 'returns a YAML front matter with nested attributes' do
    with_skill(
      content: <<~EO_SKILL
        ---
        title: My Skill
        description: A test skill
        metadata:
          dependencies:
            - skill-1
            - skill-2
          author: Muriel
        ---

        # My Skill

        Some content.
      EO_SKILL
    ) do |skill|
      expect(skill.yaml_front_matter).to eq(
        {
          'title' => 'My Skill',
          'description' => 'A test skill',
          'metadata' => {
            'dependencies' => %w[skill-1 skill-2],
            'author' => 'Muriel'
          }
        }
      )
    end
  end
end
