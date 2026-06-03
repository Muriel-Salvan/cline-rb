describe Cline::Config, '#skills' do
  context 'without project config' do
    it 'returns nil if the skills directory does not exist' do
      with_config(skills: nil) do |config|
        expect(config.skills).to be_nil
      end
    end

    it 'loads skills from the config directory' do
      with_config(
        skills: {
          'test-skill-1' => {},
          'test-skill-2' => {}
        }
      ) do |config|
        skills = config.skills
        expect(skills.keys).to eq %w[test-skill-1 test-skill-2]
        expect(skills['test-skill-1'].name).to eq 'test-skill-1'
        expect(skills['test-skill-2'].name).to eq 'test-skill-2'
      end
    end

    it 'creates skills when create: true is passed to the skills method' do
      with_config(skills: nil) do |config|
        expect(config.skills(create: true)).not_to be_nil
        new_dir = File.join(config.dir, 'skills')
        expect(File.exist?(new_dir)).to be true
        expect(File.directory?(new_dir)).to be true
      end
    end

    it 'creates skills when config is opened with create: true' do
      with_config(skills: nil) do |config|
        # Re-open the same config directory with create: true to verify it works
        expect(described_class.open(config.dir, create: true).skills).not_to be_nil
        new_dir = File.join(config.dir, 'skills')
        expect(File.exist?(new_dir)).to be true
        expect(File.directory?(new_dir)).to be true
      end
    end
  end

  context 'with project config' do
    # Build a project config instance from a separate temporary directory
    # and mock Cline::Config.project to return it.
    # Then also instantiate a global config with skills for testing.
    #
    # @param global_skills [Hash{String => Hash{Symbol => Object}}, nil] Skills definitions for the global config
    # @param project_skills [Hash{String => Hash{Symbol => Object}}, nil] Skills definitions for the project config
    # @yield [global_config, project_config] Block called with the global config and the project config ready
    # @yieldparam [Cline::Config] The global config (opened with include_project_config: true)
    # @yieldparam [Cline::Config] The project config that was mocked
    def with_configs(global_skills: nil, project_skills: nil)
      with_temp_dir do |project_dir|
        setup_config_dir(project_dir, skills: project_skills)
        project_config = Cline::Config.open(project_dir)
        allow(Cline::Config).to receive(:project).and_return(project_config)
        with_config(
          include_project_config: true,
          skills: global_skills
        ) do |global_config|
          yield global_config, project_config
        end
      end
    end

    it 'returns only global skills when the project has no skills' do
      with_configs(
        project_skills: nil,
        global_skills: {
          'global-skill-1' => {},
          'global-skill-2' => {}
        }
      ) do |config, _project_config|
        skills = config.skills
        expect(skills.keys).to eq %w[global-skill-1 global-skill-2]
        expect(skills['global-skill-1'].name).to eq 'global-skill-1'
        expect(skills['global-skill-2'].name).to eq 'global-skill-2'
      end
    end

    it 'returns global and project skills jointly through all accessors' do
      with_configs(
        project_skills: {
          'project-skill-1' => {},
          'project-skill-2' => {}
        },
        global_skills: {
          'global-skill-1' => {},
          'global-skill-2' => {}
        }
      ) do |config, _project_config|
        skills = config.skills

        # Enumerable accessors
        collected_keys = []
        skills.each do |key, value|
          collected_keys << key
          expect(value.name).to eq key
        end
        expect(collected_keys).to eq %w[global-skill-1 global-skill-2 project-skill-1 project-skill-2]
        expect(skills.map { |key, _value| key }).to eq %w[global-skill-1 global-skill-2 project-skill-1 project-skill-2]
        expect(skills.count).to eq 4
        expect(skills.size).to eq 4
        expect(skills.empty?).to be false
        expect(skills.any? { |_k, v| v.name == 'project-skill-1' }).to be true
        expect(skills.find { |_k, v| v.name == 'project-skill-2' }).not_to be_nil
        expect(skills.select { |_k, v| v.name.start_with?('project-') }.size).to eq 2
        expect(skills.reject { |_k, v| v.name.start_with?('global-') }.size).to eq 2

        # Hash accessors
        expect(skills.keys).to eq %w[global-skill-1 global-skill-2 project-skill-1 project-skill-2]
        expect(skills.values.size).to eq 4
        expect(skills['global-skill-1'].name).to eq 'global-skill-1'
        expect(skills['global-skill-2'].name).to eq 'global-skill-2'
        expect(skills['project-skill-1'].name).to eq 'project-skill-1'
        expect(skills['project-skill-2'].name).to eq 'project-skill-2'
        expect(skills.key?('project-skill-1')).to be true
        expect(skills.key?('global-skill-1')).to be true
        expect(skills.key?('non-existent-skill')).to be false
        expect(skills.to_h.keys).to eq %w[global-skill-1 global-skill-2 project-skill-1 project-skill-2]
      end
    end

    it 'returns global skills in place of project skills when they share the same name' do
      with_configs(
        project_skills: {
          'shared-skill' => { content: "# Project skill content\n" }
        },
        global_skills: {
          'global-skill' => {},
          'shared-skill' => { content: "# Global skill content\n" }
        }
      ) do |config, project_config|
        skills = config.skills
        # The shared-skill should come from the global layer (priority order)
        expect(skills.keys).to eq %w[global-skill shared-skill]
        expect(skills['shared-skill'].name).to eq 'shared-skill'
        # Verify the content is the one from the global config
        expect(skills['shared-skill'].files['SKILL.md'].content).to eq "# Global skill content\n"
        # The project skill directory should not be used
        expect(skills['shared-skill']).not_to eq project_config.skills['shared-skill']
      end
    end

    it 'returns the global skills directory' do
      with_configs(
        project_skills: {},
        global_skills: {}
      ) do |config, project_config|
        skills = config.skills
        expect(skills.dir).to eq File.join(config.dir, 'skills')
        expect(skills.dir).not_to eq File.join(project_config.skills.dir)
      end
    end

    it 'creates new skills in the global skills directory' do
      with_configs(
        project_skills: {},
        global_skills: {}
      ) do |config, project_config|
        skills = config.skills
        new_skill = skills.new('new-skill')
        expect(new_skill).to be_a(Cline::Skill)
        # The new skill should be persisted in the global skills directory
        expect(skills.key?('new-skill')).to be true
        expect(File.directory?(File.join(config.dir, 'skills', 'new-skill'))).to be true
        expect(File.directory?(File.join(project_config.dir, 'skills', 'new-skill'))).to be false
        expect(project_config.skills.key?('new-skill')).to be false
      end
    end
  end
end
