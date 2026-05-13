describe Cline::Skill, '#files' do
  it 'returns an empty hash when the skill is completely empty' do
    with_skill(content: nil) do |skill|
      expect(skill.files).to eq({})
    end
  end

  it 'returns a hash with just SKILL.md when the skill has only SKILL.md content' do
    with_skill(content: '# My Skill') do |skill|
      files = skill.files
      expect(files.keys).to contain_exactly('SKILL.md')
      expect(files['SKILL.md'].content).to eq('# My Skill')
    end
  end

  it 'includes all additional files alongside SKILL.md' do
    with_skill(
      content: '# My Skill',
      files: {
        'extra/read.md' => '# Read a file',
        'tools/file_read.py' => 'import file'
      }
    ) do |skill|
      files = skill.files
      expect(files.keys).to contain_exactly('SKILL.md', 'extra/read.md', 'tools/file_read.py')
      expect(files['SKILL.md'].content).to eq('# My Skill')
      expect(files['extra/read.md'].content).to eq('# Read a file')
      expect(files['tools/file_read.py'].content).to eq('import file')
    end
  end
end
