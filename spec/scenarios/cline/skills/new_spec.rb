describe Cline::Skills, '#new' do
  it 'creates a new skill and its directory from scratch' do
    with_config(skills: {}) do |config|
      skills = config.skills
      skill = skills.new('my-skill')
      expect(File.directory?(File.join(skills.dir, 'my-skill'))).to be true
      expect(skills['my-skill']).to eq(skill)
    end
  end

  it 'uses existing skill content when called with an existing sub-directory name' do
    with_config(skills: { 'my-skill' => { content: '# Existing skill' } }) do |config|
      skills = config.skills
      skill = skills.new('my-skill')
      expect(skills['my-skill'].files['SKILL.md'].content).to eq('# Existing skill')
      expect(skill.files['SKILL.md'].content).to eq('# Existing skill')
    end
  end
end
