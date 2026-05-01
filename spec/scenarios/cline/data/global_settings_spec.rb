describe Cline::Data, '#global_settings' do
  it 'returns nil when no global settings file exists in data directory' do
    with_data_dir(global_settings: nil) do |data_dir|
      expect(described_class.from_dir(data_dir).global_settings).to be_nil
    end
  end

  it 'ignores extra unknown parameters from global settings file' do
    with_data_dir(
      global_settings: {
        cline_web_tools_enabled: true,
        this_is_an_unknown_parameter: 'should be ignored',
        another_extra_field: 12_345,
        focus_chain_settings: {
          enabled: true,
          unknown_nested_parameter: 'also ignored',
          remind_cline_interval: 5
        }
      }
    ) do |data_dir|
      global_settings = described_class.from_dir(data_dir).global_settings
      # Verify valid attributes are still correctly loaded
      expect(global_settings.cline_web_tools_enabled).to be true
      expect(global_settings.focus_chain_settings.enabled).to be true
      expect(global_settings.focus_chain_settings.remind_cline_interval).to eq 5
      # Verify unknown parameters are not present on the object
      expect(global_settings).not_to respond_to(:this_is_an_unknown_parameter)
      expect(global_settings).not_to respond_to(:another_extra_field)
      expect(global_settings.focus_chain_settings).not_to respond_to(:unknown_nested_parameter)
    end
  end

  it 'loads all global settings attributes (features)' do
    with_data_dir(
      global_settings: {
        focus_chain_settings: {
          enabled: true,
          remind_cline_interval: 5
        },
        cline_web_tools_enabled: true,
        double_check_completion_enabled: false,
        enable_parallel_tool_calling: true,
        strict_plan_mode_enabled: false,
        subagents_enabled: true,
        use_auto_condense: false,
        native_tool_call_enabled: true,
        enable_checkpoints_setting: false,
        background_edit_enabled: true
      }
    ) do |data_dir|
      global_settings = described_class.from_dir(data_dir).global_settings
      expect(global_settings.focus_chain_settings).not_to be_nil
      expect(global_settings.focus_chain_settings.enabled).to be true
      expect(global_settings.focus_chain_settings.remind_cline_interval).to eq 5
      expect(global_settings.cline_web_tools_enabled).to be true
      expect(global_settings.double_check_completion_enabled).to be false
      expect(global_settings.enable_parallel_tool_calling).to be true
      expect(global_settings.strict_plan_mode_enabled).to be false
      expect(global_settings.subagents_enabled).to be true
      expect(global_settings.use_auto_condense).to be false
      expect(global_settings.native_tool_call_enabled).to be true
      expect(global_settings.enable_checkpoints_setting).to be false
      expect(global_settings.background_edit_enabled).to be true
    end
  end

  it 'loads all global settings attributes (models)' do
    with_data_dir(
      global_settings: {
        act_mode_open_router_model_info: {
          name: 'test-model',
          max_tokens: 4096,
          context_window: 8192,
          supports_images: true,
          supports_prompt_cache: false,
          input_price: 0.0001,
          output_price: 0.0002,
          cache_reads_price: 0.00005,
          description: 'Test model',
          thinking_config: {
            max_budget: 100
          }
        },
        plan_mode_open_router_model_info: {
          name: 'plan-model',
          max_tokens: 2048,
          context_window: 4096,
          supports_images: false,
          supports_prompt_cache: true,
          input_price: 0.00005,
          output_price: 0.0001,
          cache_reads_price: 0.00002,
          description: 'Plan model',
          thinking_config: {
            max_budget: 200
          }
        },
        act_mode_cline_model_info: {
          name: 'cline-act',
          max_tokens: 8192
        },
        plan_mode_cline_model_info: {
          name: 'cline-plan',
          max_tokens: 4096
        },
        act_mode_api_provider: 'openrouter',
        plan_mode_api_provider: 'anthropic',
        act_mode_cline_model_id: 'cline-act-01',
        plan_mode_cline_model_id: 'cline-plan-01',
        act_mode_reasoning_effort: 'high',
        plan_mode_reasoning_effort: 'low',
        plan_mode_thinking_budget_tokens: 4000,
        act_mode_thinking_budget_tokens: 8000,
        act_mode_open_router_model_id: 'openrouter/act-model'
      }
    ) do |data_dir|
      global_settings = described_class.from_dir(data_dir).global_settings
      expect(global_settings.act_mode_open_router_model_info.name).to eq 'test-model'
      expect(global_settings.act_mode_open_router_model_info.max_tokens).to eq 4096
      expect(global_settings.act_mode_open_router_model_info.context_window).to eq 8192
      expect(global_settings.act_mode_open_router_model_info.supports_images).to be true
      expect(global_settings.act_mode_open_router_model_info.supports_prompt_cache).to be false
      expect(global_settings.act_mode_open_router_model_info.input_price).to eq 0.0001
      expect(global_settings.act_mode_open_router_model_info.output_price).to eq 0.0002
      expect(global_settings.act_mode_open_router_model_info.cache_reads_price).to eq 0.00005
      expect(global_settings.act_mode_open_router_model_info.description).to eq 'Test model'
      expect(global_settings.act_mode_open_router_model_info.thinking_config.max_budget).to eq 100
      expect(global_settings.plan_mode_open_router_model_info.name).to eq 'plan-model'
      expect(global_settings.plan_mode_open_router_model_info.max_tokens).to eq 2048
      expect(global_settings.plan_mode_open_router_model_info.context_window).to eq 4096
      expect(global_settings.plan_mode_open_router_model_info.supports_images).to be false
      expect(global_settings.plan_mode_open_router_model_info.supports_prompt_cache).to be true
      expect(global_settings.plan_mode_open_router_model_info.input_price).to eq 0.00005
      expect(global_settings.plan_mode_open_router_model_info.output_price).to eq 0.0001
      expect(global_settings.plan_mode_open_router_model_info.cache_reads_price).to eq 0.00002
      expect(global_settings.plan_mode_open_router_model_info.description).to eq 'Plan model'
      expect(global_settings.plan_mode_open_router_model_info.thinking_config.max_budget).to eq 200
      expect(global_settings.act_mode_cline_model_info.name).to eq 'cline-act'
      expect(global_settings.act_mode_cline_model_info.max_tokens).to eq 8192
      expect(global_settings.plan_mode_cline_model_info.name).to eq 'cline-plan'
      expect(global_settings.plan_mode_cline_model_info.max_tokens).to eq 4096
      expect(global_settings.act_mode_api_provider).to eq 'openrouter'
      expect(global_settings.plan_mode_api_provider).to eq 'anthropic'
      expect(global_settings.act_mode_cline_model_id).to eq 'cline-act-01'
      expect(global_settings.plan_mode_cline_model_id).to eq 'cline-plan-01'
      expect(global_settings.act_mode_reasoning_effort).to eq 'high'
      expect(global_settings.plan_mode_reasoning_effort).to eq 'low'
      expect(global_settings.plan_mode_thinking_budget_tokens).to eq 4000
      expect(global_settings.act_mode_thinking_budget_tokens).to eq 8000
      expect(global_settings.act_mode_open_router_model_id).to eq 'openrouter/act-model'
    end
  end

  it 'loads all global settings attributes (auto_approval)' do
    with_data_dir(
      global_settings: {
        auto_approval_settings: {
          enabled: true,
          version: 1,
          max_requests: 10,
          enable_notifications: false,
          favorites: %w[file-read command-run],
          actions: {
            read_files: true,
            read_files_externally: false,
            edit_files: true,
            edit_files_externally: false,
            execute_safe_commands: true,
            execute_all_commands: false,
            use_browser: true,
            use_mcp: false
          }
        },
        yolo_mode_toggled: true
      }
    ) do |data_dir|
      global_settings = described_class.from_dir(data_dir).global_settings
      expect(global_settings.auto_approval_settings.enabled).to be true
      expect(global_settings.auto_approval_settings.version).to eq 1
      expect(global_settings.auto_approval_settings.max_requests).to eq 10
      expect(global_settings.auto_approval_settings.enable_notifications).to be false
      expect(global_settings.auto_approval_settings.favorites).to eq %w[file-read command-run]
      expect(global_settings.auto_approval_settings.actions.read_files).to be true
      expect(global_settings.auto_approval_settings.actions.read_files_externally).to be false
      expect(global_settings.auto_approval_settings.actions.edit_files).to be true
      expect(global_settings.auto_approval_settings.actions.edit_files_externally).to be false
      expect(global_settings.auto_approval_settings.actions.execute_safe_commands).to be true
      expect(global_settings.auto_approval_settings.actions.execute_all_commands).to be false
      expect(global_settings.auto_approval_settings.actions.use_browser).to be true
      expect(global_settings.auto_approval_settings.actions.use_mcp).to be false
      expect(global_settings.yolo_mode_toggled).to be true
    end
  end

  it 'loads all global settings attributes (browser)' do
    with_data_dir(
      global_settings: {
        browser_settings: {
          viewport: {
            width: 1280,
            height: 720
          },
          remote_browser_enabled: true,
          remote_browser_host: 'localhost:9222',
          chrome_executable_path: '/usr/bin/chrome',
          disable_tool_use: false,
          custom_args: '--no-sandbox'
        }
      }
    ) do |data_dir|
      global_settings = described_class.from_dir(data_dir).global_settings
      expect(global_settings.browser_settings.viewport.width).to eq 1280
      expect(global_settings.browser_settings.viewport.height).to eq 720
      expect(global_settings.browser_settings.remote_browser_enabled).to be true
      expect(global_settings.browser_settings.remote_browser_host).to eq 'localhost:9222'
      expect(global_settings.browser_settings.chrome_executable_path).to eq '/usr/bin/chrome'
      expect(global_settings.browser_settings.disable_tool_use).to be false
      expect(global_settings.browser_settings.custom_args).to eq '--no-sandbox'
    end
  end

  it 'loads all global settings attributes (workspace)' do
    with_data_dir(
      global_settings: {
        workspace_roots: [
          {
            path: '/workspace/project1',
            name: 'Project 1',
            vcs: 'git',
            commit_hash: 'abc123'
          },
          {
            path: '/workspace/project2',
            name: 'Project 2',
            vcs: 'git',
            commit_hash: 'def456'
          }
        ],
        primary_root_index: 0,
        multi_root_enabled: true
      }
    ) do |data_dir|
      global_settings = described_class.from_dir(data_dir).global_settings
      expect(global_settings.workspace_roots.count).to eq 2
      expect(global_settings.workspace_roots.first.path).to eq '/workspace/project1'
      expect(global_settings.workspace_roots.first.name).to eq 'Project 1'
      expect(global_settings.workspace_roots.first.vcs).to eq 'git'
      expect(global_settings.workspace_roots.first.commit_hash).to eq 'abc123'
      expect(global_settings.primary_root_index).to eq 0
      expect(global_settings.multi_root_enabled).to be true
    end
  end

  it 'loads all global settings attributes (api_providers)' do
    with_data_dir(
      global_settings: {
        open_ai_headers: { 'Authorization' => 'Bearer test' },
        sap_ai_core_use_orchestration_mode: true,
        anthropic_base_url: 'https://api.anthropic.com',
        open_router_provider_sorting: 'price',
        aws_authentication: 'profile',
        ollama_api_options_ctx_num: '8192',
        lm_studio_base_url: 'http://localhost:1234',
        lm_studio_max_tokens: '4096',
        gemini_base_url: 'https://generativelanguage.googleapis.com',
        azure_api_version: '2024-02-01',
        request_timeout_ms: 30_000
      }
    ) do |data_dir|
      global_settings = described_class.from_dir(data_dir).global_settings
      expect(global_settings.open_ai_headers.to_h).to eq({ 'Authorization' => 'Bearer test' })
      expect(global_settings.open_ai_headers['Authorization']).to eq('Bearer test')
      expect(global_settings.sap_ai_core_use_orchestration_mode).to be true
      expect(global_settings.anthropic_base_url).to eq 'https://api.anthropic.com'
      expect(global_settings.open_router_provider_sorting).to eq 'price'
      expect(global_settings.aws_authentication).to eq 'profile'
      expect(global_settings.ollama_api_options_ctx_num).to eq '8192'
      expect(global_settings.lm_studio_base_url).to eq 'http://localhost:1234'
      expect(global_settings.lm_studio_max_tokens).to eq '4096'
      expect(global_settings.gemini_base_url).to eq 'https://generativelanguage.googleapis.com'
      expect(global_settings.azure_api_version).to eq '2024-02-01'
      expect(global_settings.request_timeout_ms).to eq 30_000
    end
  end

  it 'loads all global settings attributes (general)' do
    with_data_dir(
      global_settings: {
        welcome_view_completed: true,
        custom_prompt: 'Custom prompt text',
        default_terminal_profile: 'bash',
        telemetry_setting: 'disabled',
        oca_mode: 'full',
        cline_version: '1.0.0',
        last_shown_announcement_id: 'announce-123',
        vscode_terminal_execution_mode: 'integrated',
        is_new_user: false,
        mcp_display_mode: 'list',
        last_dismissed_info_banner_version: 5,
        last_dismissed_model_banner_version: 3
      }
    ) do |data_dir|
      global_settings = described_class.from_dir(data_dir).global_settings
      expect(global_settings.welcome_view_completed).to be true
      expect(global_settings.custom_prompt).to eq 'Custom prompt text'
      expect(global_settings.default_terminal_profile).to eq 'bash'
      expect(global_settings.telemetry_setting).to eq 'disabled'
      expect(global_settings.oca_mode).to eq 'full'
      expect(global_settings.cline_version).to eq '1.0.0'
      expect(global_settings.last_shown_announcement_id).to eq 'announce-123'
      expect(global_settings.vscode_terminal_execution_mode).to eq 'integrated'
      expect(global_settings.is_new_user).to be false
      expect(global_settings.mcp_display_mode).to eq 'list'
      expect(global_settings.last_dismissed_info_banner_version).to eq 5
      expect(global_settings.last_dismissed_model_banner_version).to eq 3
    end
  end

  it 'loads all global settings attributes (toggles)' do
    with_data_dir(
      global_settings: {
        remote_rules_toggles: { 'rule1' => true, 'rule2' => false },
        remote_workflow_toggles: { 'workflow1' => true },
        global_workflow_toggles: { 'workflow_a' => false, 'workflow_b' => true },
        global_cline_rules_toggles: { 'core_rule' => true },
        remote_skills_toggles: { 'skill_x' => false, 'skill_y' => true },
        global_skills_toggles: { 'default_skill' => true }
      }
    ) do |data_dir|
      global_settings = described_class.from_dir(data_dir).global_settings
      expect(global_settings).not_to be_nil
      expect(global_settings.remote_rules_toggles.to_h).to eq({ 'rule1' => true, 'rule2' => false })
      expect(global_settings.remote_rules_toggles['rule1']).to eq true
      expect(global_settings.remote_rules_toggles['rule2']).to eq false
      expect(global_settings.remote_workflow_toggles.to_h).to eq({ 'workflow1' => true })
      expect(global_settings.global_workflow_toggles.to_h).to eq({ 'workflow_a' => false, 'workflow_b' => true })
      expect(global_settings.global_cline_rules_toggles.to_h).to eq({ 'core_rule' => true })
      expect(global_settings.remote_skills_toggles.to_h).to eq({ 'skill_x' => false, 'skill_y' => true })
      expect(global_settings.global_skills_toggles.to_h).to eq({ 'default_skill' => true })
    end
  end

  describe '#==' do
    it 'returns true when 2 global settings from different data directories have the same content' do
      settings_hash = {
        cline_web_tools_enabled: true,
        focus_chain_settings: {
          enabled: true,
          remind_cline_interval: 5
        }
      }
      with_data_dir(global_settings: settings_hash) do |data_dir1|
        settings1 = described_class.from_dir(data_dir1).global_settings
        with_data_dir(global_settings: settings_hash) do |data_dir2|
          settings2 = described_class.from_dir(data_dir2).global_settings
          # Settings are from different data directories but have identical content
          expect(settings1).not_to equal(settings2) # Different instances
          expect(settings1).to eq(settings2)
        end
      end
    end

    it 'returns false when 2 global settings have different attributes' do
      with_data_dir(global_settings: { cline_web_tools_enabled: true }) do |data_dir1|
        settings1 = described_class.from_dir(data_dir1).global_settings
        with_data_dir(global_settings: { cline_web_tools_enabled: false }) do |data_dir2|
          settings2 = described_class.from_dir(data_dir2).global_settings
          expect(settings1).not_to eq(settings2)
        end
      end
    end

    it 'returns false when 2 global settings have different nested attributes' do
      with_data_dir(global_settings: { focus_chain_settings: { enabled: true } }) do |data_dir1|
        settings1 = described_class.from_dir(data_dir1).global_settings
        with_data_dir(global_settings: { focus_chain_settings: { enabled: false } }) do |data_dir2|
          settings2 = described_class.from_dir(data_dir2).global_settings
          expect(settings1).not_to eq(settings2)
        end
      end
    end

    it 'returns false when 2 global settings have unknown attributes' do
      with_data_dir(global_settings: { focus_chain_settings: { unknown_attribute: 1 } }) do |data_dir1|
        settings1 = described_class.from_dir(data_dir1).global_settings
        with_data_dir(global_settings: { focus_chain_settings: { unknown_attribute: 2 } }) do |data_dir2|
          settings2 = described_class.from_dir(data_dir2).global_settings
          expect(settings1).not_to eq(settings2)
        end
      end
    end
  end
end
