describe Cline::Workspace, '#==' do
  it 'returns true when 2 workspaces from different data directories have the same settings' do
    settings_hash = {
      localSkillsToggles: { skill1: true, skill2: false },
      localClineRulesToggles: { rule1: true }
    }

    with_workspace(settings: settings_hash) do |workspace1|
      with_workspace(name: 'test-workspace-2', settings: settings_hash) do |workspace2|
        # Workspaces are from different data directories but have identical settings
        expect(workspace1).not_to equal(workspace2) # Different instances
        expect(workspace1).to eq(workspace2)
        expect(workspace1.settings).not_to equal(workspace2.settings)
        expect(workspace1.settings).to eq(workspace2.settings)
      end
    end
  end

  it 'returns false when 2 workspaces have different setting attributes' do
    with_workspace(settings: { localSkillsToggles: { skill1: true } }) do |workspace1|
      with_workspace(settings: { localSkillsToggles: { skill1: false } }) do |workspace2|
        expect(workspace1).not_to eq(workspace2)
        expect(workspace1.settings).not_to eq(workspace2.settings)
      end
    end
  end

  it 'returns false when 2 workspaces have different setting attributes that are unknown' do
    with_workspace(settings: { unknownAttribute: 1 }) do |workspace1|
      with_workspace(settings: { unknownAttribute: 2 }) do |workspace2|
        expect(workspace1).not_to eq(workspace2)
        expect(workspace1.settings).not_to eq(workspace2.settings)
      end
    end
  end
end
