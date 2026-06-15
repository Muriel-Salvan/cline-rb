describe Cline::Skill, '#enable' do
  it 'does nothing when SKILL.md does not exist' do
    with_skill(content: nil) do |skill|
      expect { skill.enable }.not_to raise_error
      expect(skill.yaml_front_matter).to be_nil
    end
  end

  it 'does nothing when SKILL.md has no YAML front matter' do
    with_skill(
      content: <<~EO_SKILL
        # My Skill

        Some content without front matter.
      EO_SKILL
    ) do |skill|
      skill.enable
      expect(skill.yaml_front_matter).to eq({})
    end
  end

  it 'does nothing when the skill is already enabled (no disabled key)' do
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
      skill.enable
      expect(skill.yaml_front_matter).to eq(
        {
          title: 'My Skill',
          description: 'A test skill'
        }
      )
    end
  end

  it 'does nothing when disabled is set to false' do
    with_skill(
      content: <<~EO_SKILL
        ---
        title: My Skill
        disabled: false
        ---

        # My Skill

        Some content.
      EO_SKILL
    ) do |skill|
      skill.enable
      expect(skill.yaml_front_matter).to eq(
        {
          title: 'My Skill',
          disabled: false
        }
      )
    end
  end

  it 'removes the disabled key from the front matter when the skill is disabled' do
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
      skill.enable
      expect(skill.yaml_front_matter).to eq(
        {
          title: 'My Skill',
          description: 'A test skill'
        }
      )
    end
  end

  it 'leaves the SKILL.md body content untouched' do
    with_skill(
      content: <<~EO_SKILL
        ---
        title: My Skill
        disabled: true
        ---

        # My Skill

        Some content.
      EO_SKILL
    ) do |skill|
      skill.enable
      expect(skill.files['SKILL.md'].content).to eq <<~EO_SKILL
        ---
        title: My Skill
        ---

        # My Skill

        Some content.
      EO_SKILL
    end
  end
end
