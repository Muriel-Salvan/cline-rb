describe Cline::WorkspaceSettings, '#save' do
  it 'persists modified attributes to the workspaceState.json file' do
    with_workspace(
      settings: {
        localSkillsToggles: { skill1: true, skill2: false }
      }
    ) do |workspace|
      settings = workspace.settings
      settings.local_skills_toggles['skill1'] = false
      settings.local_skills_toggles['skill3'] = true
      settings.save
      expect(JSON.parse(File.read(File.join(workspace.dir, 'workspaceState.json')))).to eq(
        {
          'localSkillsToggles' => {
            'skill1' => false,
            'skill2' => false,
            'skill3' => true
          }
        }
      )
    end
  end

  it 'persists unknown attributes to the workspaceState.json file' do
    with_workspace(
      settings: {
        localSkillsToggles: { skill1: true, skill2: false },
        unknownParameter: 'Unknown value'
      }
    ) do |workspace|
      settings = workspace.settings
      settings.local_skills_toggles['skill1'] = false
      settings.local_skills_toggles['skill3'] = true
      settings.save
      expect(JSON.parse(File.read(File.join(workspace.dir, 'workspaceState.json')))).to eq(
        {
          'localSkillsToggles' => {
            'skill1' => false,
            'skill2' => false,
            'skill3' => true
          },
          'unknownParameter' => 'Unknown value'
        }
      )
    end
  end

  it 'persists a newly instantiated workspace settings file' do
    with_data(workspaces: { 'test-workspace' => {} }) do |data|
      workspace = data.workspaces['test-workspace']
      settings = workspace.settings(create: true)
      settings.local_skills_toggles = Cline::Utils::Schema.map(:boolean).new
      settings.local_skills_toggles['skill1'] = true
      settings.save
      expect(JSON.parse(File.read(File.join(workspace.dir, 'workspaceState.json')))).to eq(
        {
          'localSkillsToggles' => {
            'skill1' => true
          }
        }
      )
    end
  end
end
