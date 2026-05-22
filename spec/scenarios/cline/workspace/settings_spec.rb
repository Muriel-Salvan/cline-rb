describe Cline::Workspace, '#settings' do
  it 'returns nil when no workspaceState.json file exists in workspace directory' do
    with_workspace(settings: nil) do |workspace|
      expect(workspace.settings).to be_nil
    end
  end

  it 'ignores extra unknown parameters from workspaceState.json file' do
    with_workspace(
      settings: {
        localSkillsToggles: { skill1: true, skill2: false },
        localClineRulesToggles: { rule1: true },
        thisIsAnUnknownParameter: 'should be ignored',
        anotherExtraField: 12_345
      }
    ) do |workspace|
      settings = workspace.settings
      # Verify valid attributes are still correctly loaded
      expect(settings.local_skills_toggles.to_h).to eq({ 'skill1' => true, 'skill2' => false })
      expect(settings.local_cline_rules_toggles.to_h).to eq({ 'rule1' => true })
      # Verify unknown parameters are not present on the object
      expect(settings).not_to respond_to(:this_is_an_unknown_parameter)
      expect(settings).not_to respond_to(:thisIsAnUnknownParameter)
      expect(settings).not_to respond_to(:another_extra_field)
      expect(settings).not_to respond_to(:anotherExtraField)
    end
  end

  it 'loads all settings' do
    with_workspace(
      settings: {
        localSkillsToggles: { skill1: true, skill2: false, skill3: true },
        localClineRulesToggles: { rule1: true, rule2: false },
        localAgentsRulesToggles: { agent1: false, agent2: true },
        workflowToggles: { flow1: true, flow2: true, flow3: false },
        localWindsurfRulesToggles: { windsurf1: false },
        localCursorRulesToggles: { cursor1: true, cursor2: true },
        __vscodeMigrationVersion: 7
      }
    ) do |workspace|
      settings = workspace.settings
      expect(settings.local_skills_toggles.to_h).to eq({ 'skill1' => true, 'skill2' => false, 'skill3' => true })
      expect(settings.local_skills_toggles['skill1']).to be true
      expect(settings.local_skills_toggles['skill2']).to be false
      expect(settings.local_skills_toggles['skill3']).to be true
      expect(settings.local_cline_rules_toggles.to_h).to eq({ 'rule1' => true, 'rule2' => false })
      expect(settings.local_agents_rules_toggles.to_h).to eq({ 'agent1' => false, 'agent2' => true })
      expect(settings.workflow_toggles.to_h).to eq({ 'flow1' => true, 'flow2' => true, 'flow3' => false })
      expect(settings.local_windsurf_rules_toggles.to_h).to eq({ 'windsurf1' => false })
      expect(settings.local_cursor_rules_toggles.to_h).to eq({ 'cursor1' => true, 'cursor2' => true })
      expect(settings.__vscode_migration_version).to eq 7
    end
  end
end
