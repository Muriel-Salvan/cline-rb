describe Cline::WorkspaceSettings, '#cast' do
  # @return [Cline::WorkspaceSettings] A workspace settings instance to be tested
  attr_reader :settings

  around do |example|
    with_workspace do |workspace|
      @settings = workspace.settings(create: true)
      example.run
    end
  end

  it 'initializes local_skills_toggles map from Hash' do
    settings.local_skills_toggles = { 'skill1' => true, 'skill2' => false }
    expect(settings.local_skills_toggles.size).to eq 2
    expect(settings.local_skills_toggles['skill1']).to be true
    expect(settings.local_skills_toggles['skill2']).to be false
  end

  it 'initializes local_cline_rules_toggles map from Hash' do
    settings.local_cline_rules_toggles = { 'rule1' => true, 'rule2' => false }
    expect(settings.local_cline_rules_toggles.size).to eq 2
    expect(settings.local_cline_rules_toggles['rule1']).to be true
    expect(settings.local_cline_rules_toggles['rule2']).to be false
  end

  it 'initializes local_agents_rules_toggles map from Hash' do
    settings.local_agents_rules_toggles = { 'rule1' => true, 'rule2' => false }
    expect(settings.local_agents_rules_toggles.size).to eq 2
    expect(settings.local_agents_rules_toggles['rule1']).to be true
    expect(settings.local_agents_rules_toggles['rule2']).to be false
  end

  it 'initializes workflow_toggles map from Hash' do
    settings.workflow_toggles = { 'workflow1' => true, 'workflow2' => false }
    expect(settings.workflow_toggles.size).to eq 2
    expect(settings.workflow_toggles['workflow1']).to be true
    expect(settings.workflow_toggles['workflow2']).to be false
  end

  it 'initializes local_windsurf_rules_toggles map from Hash' do
    settings.local_windsurf_rules_toggles = { 'rule1' => true, 'rule2' => false }
    expect(settings.local_windsurf_rules_toggles.size).to eq 2
    expect(settings.local_windsurf_rules_toggles['rule1']).to be true
    expect(settings.local_windsurf_rules_toggles['rule2']).to be false
  end

  it 'initializes local_cursor_rules_toggles map from Hash' do
    settings.local_cursor_rules_toggles = { 'rule1' => true, 'rule2' => false }
    expect(settings.local_cursor_rules_toggles.size).to eq 2
    expect(settings.local_cursor_rules_toggles['rule1']).to be true
    expect(settings.local_cursor_rules_toggles['rule2']).to be false
  end
end
