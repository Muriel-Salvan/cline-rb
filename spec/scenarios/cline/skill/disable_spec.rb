describe Cline::Skill, '#disable' do
  it 'creates a disabled SKILL.md if it does not exist' do
    with_skill(content: nil) do |skill|
      expect { skill.disable }.not_to raise_error
      expect(skill.yaml_front_matter).to eq(
        {
          'disabled' => true
        }
      )
    end
  end

  it 'does nothing when the skill is already disabled (disabled is truthy)' do
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
      skill.disable
      expect(skill.yaml_front_matter).to eq(
        {
          'title' => 'My Skill',
          'description' => 'A test skill',
          'disabled' => true
        }
      )
    end
  end

  it 'adds the disabled key to the front matter when the skill is enabled' do
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
      skill.disable
      expect(skill.yaml_front_matter).to eq(
        {
          'title' => 'My Skill',
          'description' => 'A test skill',
          'disabled' => true
        }
      )
    end
  end

  it 'overrides disabled: false to disabled: true' do
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
      skill.disable
      expect(skill.yaml_front_matter).to eq(
        {
          'title' => 'My Skill',
          'disabled' => true
        }
      )
    end
  end

  it 'leaves the SKILL.md body content untouched' do
    with_skill(
      content: <<~EO_SKILL
        ---
        title: My Skill
        ---

        # My Skill

        Some content.
      EO_SKILL
    ) do |skill|
      skill.disable
      expect(skill.files['SKILL.md'].content).to eq <<~EO_SKILL
        ---
        title: My Skill
        disabled: true
        ---

        # My Skill

        Some content.
      EO_SKILL
    end
  end
end
