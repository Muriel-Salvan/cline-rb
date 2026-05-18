describe Cline::Skill, '#save' do
  it 'raises an error if not initialized from a directory' do
    skill = described_class.new

    expect { skill.save }.to raise_error('This instance has not been initialized from a Skill directory')
  end

  it 'saves modified file content to disk' do
    with_skill(
      content: '# Original SKILL',
      files: { 'script.py' => 'print("hello")' }
    ) do |skill|
      # Modify a file's content in memory
      skill.files['script.py'] = Cline::FileContent.new('print("world")')
      skill.save
      # The modified file should be updated on disk
      expect(File.read(File.join(skill.dir, 'script.py'))).to eq('print("world")')
      # Other files (SKILL.md) should remain unchanged
      expect(File.read(File.join(skill.dir, 'SKILL.md'))).to eq('# Original SKILL')
    end
  end

  it 'creates new files on disk' do
    with_skill(content: '# My Skill') do |skill|
      # Add a brand new file in memory
      skill.files['new_file.txt'] = Cline::FileContent.new('new content')
      skill.save
      # The new file should be created on disk
      new_file_path = File.join(skill.dir, 'new_file.txt')
      expect(File).to exist(new_file_path)
      expect(File.read(new_file_path)).to eq('new content')
      # The existing SKILL.md should still be there
      expect(File).to exist(File.join(skill.dir, 'SKILL.md'))
    end
  end

  it 'removes a file when set to nil' do
    with_skill(
      content: '# My Skill',
      files: { 'to_delete.txt' => 'delete me' }
    ) do |skill|
      file_path = File.join(skill.dir, 'to_delete.txt')
      expect(File).to exist(file_path)
      # Remove the file by setting its value to nil
      skill.files['to_delete.txt'] = nil
      skill.save
      expect(File).not_to exist(file_path)
    end
  end

  it 'removes a file when deleted from the hash' do
    with_skill(
      content: '# My Skill',
      files: { 'to_delete.txt' => 'delete me' }
    ) do |skill|
      file_path = File.join(skill.dir, 'to_delete.txt')
      expect(File).to exist(file_path)
      # Remove the file by deleting it from the hash
      skill.files.delete('to_delete.txt')
      skill.save
      expect(File).not_to exist(file_path)
    end
  end
end
