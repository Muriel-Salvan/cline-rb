describe Cline::Workspaces, '#new' do
  it 'creates a new workspace and its directory from scratch' do
    with_data(workspaces: {}) do |data|
      workspaces = data.workspaces
      workspace = workspaces.new('my-workspace')
      expect(File.directory?(File.join(workspaces.dir, 'my-workspace'))).to be true
      expect(workspaces['my-workspace']).to eq(workspace)
    end
  end

  it 'uses existing workspace content when called with an existing sub-directory name' do
    with_data(
      workspaces: {
        'my-workspace' => {
          settings: {
            localSkillsToggles: { skill1: true }
          }
        }
      }
    ) do |data|
      workspaces = data.workspaces
      workspace = workspaces.new('my-workspace')
      expect(workspaces['my-workspace'].settings.local_skills_toggles.to_h).to eq({ 'skill1' => true })
      expect(workspace.settings.local_skills_toggles.to_h).to eq({ 'skill1' => true })
    end
  end

  it 'creates child settings objects when accessed on a newly created workspace' do
    with_data(workspaces: {}) do |data|
      workspaces = data.workspaces
      workspace = workspaces.new('my-workspace')
      expect(File.exist?(File.join(workspace.dir, 'workspaceState.json'))).to be false
      settings = workspace.settings
      expect(File.exist?(File.join(workspace.dir, 'workspaceState.json'))).to be true
      expect(settings).not_to be_nil
    end
  end
end
