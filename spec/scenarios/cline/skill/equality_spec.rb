describe Cline::Skill, '#==' do
  it 'returns true when 2 different skill instances with the same name have the same files' do
    with_config(
      skills: {
        'test-skill' => {
          content: '# My Skill',
          files: {
            'extra/read.md' => '# Read a file',
            'tools/file_read.py' => 'import file'
          }
        }
      }
    ) do |config1|
      with_config(
        skills: {
          'test-skill' => {
            content: '# My Skill',
            files: {
              'extra/read.md' => '# Read a file',
              'tools/file_read.py' => 'import file'
            }
          }
        }
      ) do |config2|
        expect(config1.skills['test-skill'] == config2.skills['test-skill']).to be true
      end
    end
  end

  it 'returns false when skills differ by a new file' do
    with_config(
      skills: {
        'test-skill' => {
          content: '# My Skill',
          files: {
            'extra/read.md' => '# Read a file'
          }
        }
      }
    ) do |config1|
      with_config(
        skills: {
          'test-skill' => {
            content: '# My Skill',
            files: {
              'extra/read.md' => '# Read a file',
              'tools/file_read.py' => 'import file'
            }
          }
        }
      ) do |config2|
        expect(config1.skills['test-skill'] == config2.skills['test-skill']).to be false
      end
    end
  end

  it 'returns false when skills differ only by a content change in 1 file' do
    with_config(
      skills: {
        'test-skill' => {
          content: '# My Skill',
          files: {
            'extra/read.md' => '# Read a file',
            'tools/file_read.py' => 'import file'
          }
        }
      }
    ) do |config1|
      with_config(
        skills: {
          'test-skill' => {
            content: '# My Skill',
            files: {
              'extra/read.md' => '# Read a file',
              'tools/file_read.py' => 'import different_file'
            }
          }
        }
      ) do |config2|
        expect(config1.skills['test-skill'] == config2.skills['test-skill']).to be false
      end
    end
  end

  it 'returns false when skills have different names' do
    with_config(
      skills: {
        'skill-a' => {
          content: '# My Skill'
        },
        'skill-b' => {
          content: '# My Skill'
        }
      }
    ) do |config|
      expect(config.skills['skill-a'] == config.skills['skill-b']).to be false
    end
  end
end
