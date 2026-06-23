describe Cline::GlobalState, '#cast' do
  # @return [Cline::GlobalState] A global state instance to be tested
  attr_reader :global_state

  around do |example|
    with_global_state(create: true) do |global_state|
      @global_state = global_state
      example.run
    end
  end

  it 'initializes auto_approval_settings with nested AutoApprovalActions from Hash' do
    global_state.auto_approval_settings = {
      actions: {
        read_files: true,
        edit_files: true,
        execute_safe_commands: false
      },
      enabled: true,
      max_requests: 5
    }
    expect(global_state.auto_approval_settings.actions.read_files).to be true
    expect(global_state.auto_approval_settings.actions.edit_files).to be true
    expect(global_state.auto_approval_settings.actions.execute_safe_commands).to be false
    expect(global_state.auto_approval_settings.actions.read_files_externally).to be_nil
    expect(global_state.auto_approval_settings.enabled).to be true
    expect(global_state.auto_approval_settings.max_requests).to eq 5
  end

  it 'initializes browser_settings with nested BrowserViewport from Hash' do
    global_state.browser_settings = {
      viewport: {
        width: 1280,
        height: 720
      },
      remote_browser_enabled: true
    }
    expect(global_state.browser_settings.viewport.width).to eq 1280
    expect(global_state.browser_settings.viewport.height).to eq 720
    expect(global_state.browser_settings.remote_browser_enabled).to be true
  end

  it 'initializes workspace_roots collection from Array of Hashes' do
    global_state.workspace_roots = [
      { path: '/workspace/one', name: 'Project One', vcs: 'git' },
      { path: '/workspace/two', name: 'Project Two' }
    ]
    expect(global_state.workspace_roots.size).to eq 2
    expect(global_state.workspace_roots[0].path).to eq '/workspace/one'
    expect(global_state.workspace_roots[0].name).to eq 'Project One'
    expect(global_state.workspace_roots[0].vcs).to eq 'git'
    expect(global_state.workspace_roots[1].path).to eq '/workspace/two'
    expect(global_state.workspace_roots[1].name).to eq 'Project Two'
    expect(global_state.workspace_roots[1].vcs).to be_nil
  end

  it 'initializes focus_chain_settings from Hash' do
    global_state.focus_chain_settings = {
      enabled: true,
      remind_cline_interval: 10
    }
    expect(global_state.focus_chain_settings.enabled).to be true
    expect(global_state.focus_chain_settings.remind_cline_interval).to eq 10
  end

  it 'initializes OpenRouterModelInfo with nested ThinkingConfig from Hash' do
    global_state.act_mode_open_router_model_info = {
      name: 'test-model',
      max_tokens: 4096,
      thinking_config: {
        max_budget: 2000
      }
    }
    expect(global_state.act_mode_open_router_model_info.name).to eq 'test-model'
    expect(global_state.act_mode_open_router_model_info.max_tokens).to eq 4096
    expect(global_state.act_mode_open_router_model_info.thinking_config.max_budget).to eq 2000
  end

  it 'initializes OpenRouterModelInfo with nested ThinkingConfig from Hash for plan mode' do
    global_state.plan_mode_open_router_model_info = {
      name: 'test-model',
      max_tokens: 4096,
      thinking_config: {
        max_budget: 2000
      }
    }
    expect(global_state.plan_mode_open_router_model_info.name).to eq 'test-model'
    expect(global_state.plan_mode_open_router_model_info.max_tokens).to eq 4096
    expect(global_state.plan_mode_open_router_model_info.thinking_config.max_budget).to eq 2000
  end

  it 'initializes OpenRouterModelInfo with nested ThinkingConfig from Hash for act mode Cline' do
    global_state.act_mode_cline_model_info = {
      name: 'test-model',
      max_tokens: 4096,
      thinking_config: {
        max_budget: 2000
      }
    }
    expect(global_state.act_mode_cline_model_info.name).to eq 'test-model'
    expect(global_state.act_mode_cline_model_info.max_tokens).to eq 4096
    expect(global_state.act_mode_cline_model_info.thinking_config.max_budget).to eq 2000
  end

  it 'initializes OpenRouterModelInfo with nested ThinkingConfig from Hash for plan mode Cline' do
    global_state.plan_mode_cline_model_info = {
      name: 'test-model',
      max_tokens: 4096,
      thinking_config: {
        max_budget: 2000
      }
    }
    expect(global_state.plan_mode_cline_model_info.name).to eq 'test-model'
    expect(global_state.plan_mode_cline_model_info.max_tokens).to eq 4096
    expect(global_state.plan_mode_cline_model_info.thinking_config.max_budget).to eq 2000
  end

  it 'initializes dismissed_banners collection from Array of Hashes' do
    global_state.dismissed_banners = [
      { banner_id: 'welcome-banner', dismissed_at: 1_000_000 },
      { banner_id: 'update-banner', dismissed_at: 2_000_000 }
    ]
    expect(global_state.dismissed_banners.size).to eq 2
    expect(global_state.dismissed_banners[0].banner_id).to eq 'welcome-banner'
    expect(global_state.dismissed_banners[0].dismissed_at).to eq 1_000_000
    expect(global_state.dismissed_banners[1].banner_id).to eq 'update-banner'
    expect(global_state.dismissed_banners[1].dismissed_at).to eq 2_000_000
  end

  it 'initializes open_ai_headers map from Hash' do
    global_state.open_ai_headers = {
      'Authorization' => 'Bearer token1',
      'X-Custom-Header' => 'value1'
    }
    expect(global_state.open_ai_headers.size).to eq 2
    expect(global_state.open_ai_headers['Authorization']).to eq 'Bearer token1'
    expect(global_state.open_ai_headers['X-Custom-Header']).to eq 'value1'
  end

  it 'initializes remote_rules_toggles map from Hash' do
    global_state.remote_rules_toggles = {
      'rule1' => true,
      'rule2' => false
    }
    expect(global_state.remote_rules_toggles.size).to eq 2
    expect(global_state.remote_rules_toggles['rule1']).to be true
    expect(global_state.remote_rules_toggles['rule2']).to be false
  end

  it 'initializes remote_workflow_toggles map from Hash' do
    global_state.remote_workflow_toggles = {
      'workflow1' => true,
      'workflow2' => false
    }
    expect(global_state.remote_workflow_toggles.size).to eq 2
    expect(global_state.remote_workflow_toggles['workflow1']).to be true
    expect(global_state.remote_workflow_toggles['workflow2']).to be false
  end

  it 'initializes global_workflow_toggles map from Hash' do
    global_state.global_workflow_toggles = {
      'workflow1' => true,
      'workflow2' => false
    }
    expect(global_state.global_workflow_toggles.size).to eq 2
    expect(global_state.global_workflow_toggles['workflow1']).to be true
    expect(global_state.global_workflow_toggles['workflow2']).to be false
  end

  it 'initializes global_cline_rules_toggles map from Hash' do
    global_state.global_cline_rules_toggles = {
      'rule1' => true,
      'rule2' => false
    }
    expect(global_state.global_cline_rules_toggles.size).to eq 2
    expect(global_state.global_cline_rules_toggles['rule1']).to be true
    expect(global_state.global_cline_rules_toggles['rule2']).to be false
  end

  it 'initializes remote_skills_toggles map from Hash' do
    global_state.remote_skills_toggles = {
      'skill1' => true,
      'skill2' => false
    }
    expect(global_state.remote_skills_toggles.size).to eq 2
    expect(global_state.remote_skills_toggles['skill1']).to be true
    expect(global_state.remote_skills_toggles['skill2']).to be false
  end

  it 'initializes global_skills_toggles map from Hash' do
    global_state.global_skills_toggles = {
      'skill1' => true,
      'skill2' => false
    }
    expect(global_state.global_skills_toggles.size).to eq 2
    expect(global_state.global_skills_toggles['skill1']).to be true
    expect(global_state.global_skills_toggles['skill2']).to be false
  end
end
