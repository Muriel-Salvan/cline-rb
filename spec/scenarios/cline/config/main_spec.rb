describe Cline::Config, '.main' do
  around do |example|
    original_main = described_class.instance_variable_get(:@main)
    original_project = described_class.instance_variable_get(:@project)
    begin
      described_class.remove_instance_variable(:@main) if described_class.instance_variable_defined?(:@main)
      described_class.remove_instance_variable(:@project) if described_class.instance_variable_defined?(:@project)

      with_temp_dir do |tmp_dir|
        @tmp_dir = tmp_dir.gsub('\\', '/')
        cline_dir = File.join(tmp_dir, '.cline')
        FileUtils.mkdir_p(cline_dir)
        setup_config_dir(
          cline_dir,
          skills: {
            'global-skill-1' => {},
            'global-skill-2' => {}
          },
          global_state: { defaultTerminalProfile: 'test-profile' }
        )

        with_temp_dir do |project_tmp_dir|
          @project_tmp_dir = project_tmp_dir.gsub('\\', '/')
          project_cline_dir = File.join(project_tmp_dir, '.cline')
          FileUtils.mkdir_p(project_cline_dir)
          setup_config_dir(
            project_cline_dir,
            skills: {
              'project-skill-1' => {},
              'project-skill-2' => {}
            },
            global_state: { clineWebToolsEnabled: true }
          )
          Dir.chdir(project_tmp_dir) { example.run }
        end
      end
    ensure
      described_class.instance_variable_set(:@main, original_main)
      described_class.instance_variable_set(:@project, original_project)
    end
  end

  # @return [String] The temporary directory that contains the .cline config dir
  attr_reader :tmp_dir

  context 'when the host OS is mingw32' do
    around do |example|
      with_host_os('mingw32') do
        example.call
      end
    end

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('USERPROFILE').and_return(tmp_dir)
    end

    it 'loads main config from USERPROFILE/.cline with project config included' do
      main = described_class.main
      expect(main.global_state.default_terminal_profile).to eq 'test-profile'
      # Skills are taken from both global and project configs
      skills = main.skills
      expect(skills).not_to be_nil
      expect(skills.key?('global-skill-1')).to be true
      expect(skills.key?('global-skill-2')).to be true
      expect(skills.key?('project-skill-1')).to be true
      expect(skills.key?('project-skill-2')).to be true
      expect(skills['global-skill-1'].name).to eq 'global-skill-1'
      expect(skills['global-skill-2'].name).to eq 'global-skill-2'
      expect(skills['project-skill-1'].name).to eq 'project-skill-1'
      expect(skills['project-skill-2'].name).to eq 'project-skill-2'
    end
  end

  context 'when the host OS is linux' do
    around do |example|
      with_host_os('linux') do
        # Remove the user_home_dir cache
        original_user_home_dir = Cline::Utils::Os.instance_variable_get(:@user_home_dir)
        begin
          Cline::Utils::Os.remove_instance_variable(:@user_home_dir) if Cline::Utils::Os.instance_variable_defined?(:@user_home_dir)
          example.call
        ensure
          Cline::Utils::Os.instance_variable_set(:@user_home_dir, original_user_home_dir)
        end
      end
    end

    before do
      allow(Cline::Utils::Os).to receive(:`).and_call_original
      allow(Cline::Utils::Os).to receive(:`).with('eval echo ~$USER').and_return(tmp_dir)
    end

    it 'loads main config from HOME/.cline with project config included' do
      main = described_class.main
      expect(main.global_state.default_terminal_profile).to eq 'test-profile'
      # Skills are taken from both global and project configs
      skills = main.skills
      expect(skills).not_to be_nil
      expect(skills.key?('global-skill-1')).to be true
      expect(skills.key?('global-skill-2')).to be true
      expect(skills.key?('project-skill-1')).to be true
      expect(skills.key?('project-skill-2')).to be true
      expect(skills['global-skill-1'].name).to eq 'global-skill-1'
      expect(skills['global-skill-2'].name).to eq 'global-skill-2'
      expect(skills['project-skill-1'].name).to eq 'project-skill-1'
      expect(skills['project-skill-2'].name).to eq 'project-skill-2'
    end
  end
end
