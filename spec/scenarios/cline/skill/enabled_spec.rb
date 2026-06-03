describe Cline::Skill, '#enabled?' do
  it 'returns true when SKILL.md does not exist' do
    with_skill(content: nil) do |skill|
      expect(skill.enabled?).to be true
    end
  end

  it 'returns true when SKILL.md has no YAML front matter' do
    with_skill(
      content: <<~EO_SKILL
        # My Skill

        Some content without front matter.
      EO_SKILL
    ) do |skill|
      expect(skill.enabled?).to be true
    end
  end

  it 'returns true when SKILL.md has front matter with normal attributes' do
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
      expect(skill.enabled?).to be true
    end
  end

  it 'returns false when SKILL.md has front matter with disabled: true' do
    with_skill(
      content: <<~EO_SKILL
        ---
        title: My Skill
        description: A test skill
        disabled: true
        ---

        # My Skill

        Some content.
      EO_SKILL
    ) do |skill|
      expect(skill.enabled?).to be false
    end
  end
end
