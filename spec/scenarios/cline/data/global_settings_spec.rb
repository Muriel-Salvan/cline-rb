describe Cline::Data, '#global_settings' do
  it 'returns nil when no global settings file exists in data directory' do
    with_data(global_settings: nil) do |data|
      expect(data.global_settings).to be_nil
    end
  end

  it 'initializes global_settings when data is initialized with create option' do
    with_data(global_settings: nil, create: true) do |data|
      expect(data.global_settings).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'globalState.json'))).to be true
    end
  end

  it 'initializes global_settings when create option is given' do
    with_data(global_settings: nil) do |data|
      expect(data.global_settings(create: true)).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'globalState.json'))).to be true
    end
  end

  it 'ignores extra unknown parameters from global settings file' do
    with_data(
      global_settings: {
        clineWebToolsEnabled: true,
        thisIsAnUnknownParameter: 'should be ignored',
        anotherExtraField: 12_345,
        focusChainSettings: {
          enabled: true,
          unknownNestedParameter: 'also ignored',
          remindClineInterval: 5
        }
      }
    ) do |data|
      global_settings = data.global_settings
      # Verify valid attributes are still correctly loaded
      expect(global_settings.cline_web_tools_enabled).to be true
      expect(global_settings.focus_chain_settings.enabled).to be true
      expect(global_settings.focus_chain_settings.remind_cline_interval).to eq 5
      # Verify unknown parameters are not present on the object
      expect(global_settings).not_to respond_to(:this_is_an_unknown_parameter)
      expect(global_settings).not_to respond_to(:thisIsAnUnknownParameter)
      expect(global_settings).not_to respond_to(:another_extra_field)
      expect(global_settings).not_to respond_to(:anotherExtraField)
      expect(global_settings.focus_chain_settings).not_to respond_to(:unknown_nested_parameter)
      expect(global_settings.focus_chain_settings).not_to respond_to(:unknownNestedParameter)
    end
  end

  it 'loads all global settings attributes (features)' do
    with_data(
      global_settings: {
        focusChainSettings: {
          enabled: true,
          remindClineInterval: 5
        },
        clineWebToolsEnabled: true,
        doubleCheckCompletionEnabled: false,
        enableParallelToolCalling: true,
        strictPlanModeEnabled: false,
        subagentsEnabled: true,
        useAutoCondense: false,
        nativeToolCallEnabled: true,
        enableCheckpointsSetting: false,
        backgroundEditEnabled: true
      }
    ) do |data|
      global_settings = data.global_settings
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
    with_data(
      global_settings: {
        actModeOpenRouterModelInfo: {
          name: 'test-model',
          maxTokens: 4096,
          contextWindow: 8192,
          supportsImages: true,
          supportsPromptCache: false,
          inputPrice: 0.0001,
          outputPrice: 0.0002,
          cacheReadsPrice: 0.00005,
          description: 'Test model',
          thinkingConfig: {
            maxBudget: 100
          }
        },
        planModeOpenRouterModelInfo: {
          name: 'plan-model',
          maxTokens: 2048,
          contextWindow: 4096,
          supportsImages: false,
          supportsPromptCache: true,
          inputPrice: 0.00005,
          outputPrice: 0.0001,
          cacheReadsPrice: 0.00002,
          description: 'Plan model',
          thinkingConfig: {
            maxBudget: 200
          }
        },
        actModeClineModelInfo: {
          name: 'cline-act',
          maxTokens: 8192
        },
        planModeClineModelInfo: {
          name: 'cline-plan',
          maxTokens: 4096
        },
        actModeApiProvider: 'openrouter',
        planModeApiProvider: 'anthropic',
        actModeClineModelId: 'cline-act-01',
        planModeClineModelId: 'cline-plan-01',
        actModeReasoningEffort: 'high',
        planModeReasoningEffort: 'low',
        planModeThinkingBudgetTokens: 4000,
        actModeThinkingBudgetTokens: 8000,
        actModeOpenRouterModelId: 'openrouter/act-model'
      }
    ) do |data|
      global_settings = data.global_settings
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
    with_data(
      global_settings: {
        autoApprovalSettings: {
          enabled: true,
          version: 1,
          maxRequests: 10,
          enableNotifications: false,
          favorites: %w[file-read command-run],
          actions: {
            readFiles: true,
            readFilesExternally: false,
            editFiles: true,
            editFilesExternally: false,
            executeSafeCommands: true,
            executeAllCommands: false,
            useBrowser: true,
            useMcp: false
          }
        },
        yoloModeToggled: true
      }
    ) do |data|
      global_settings = data.global_settings
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
    with_data(
      global_settings: {
        browserSettings: {
          viewport: {
            width: 1280,
            height: 720
          },
          remoteBrowserEnabled: true,
          remoteBrowserHost: 'localhost:9222',
          chromeExecutablePath: '/usr/bin/chrome',
          disableToolUse: false,
          customArgs: '--no-sandbox'
        }
      }
    ) do |data|
      global_settings = data.global_settings
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
    with_data(
      global_settings: {
        workspaceRoots: [
          {
            path: '/workspace/project1',
            name: 'Project 1',
            vcs: 'git',
            commitHash: 'abc123'
          },
          {
            path: '/workspace/project2',
            name: 'Project 2',
            vcs: 'git',
            commitHash: 'def456'
          }
        ],
        primaryRootIndex: 0,
        multiRootEnabled: true
      }
    ) do |data|
      global_settings = data.global_settings
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
    with_data(
      global_settings: {
        openAiHeaders: { 'Authorization' => 'Bearer test' },
        sapAiCoreUseOrchestrationMode: true,
        anthropicBaseUrl: 'https://api.anthropic.com',
        openRouterProviderSorting: 'price',
        awsAuthentication: 'profile',
        ollamaApiOptionsCtxNum: '8192',
        lmStudioBaseUrl: 'http://localhost:1234',
        lmStudioMaxTokens: '4096',
        geminiBaseUrl: 'https://generativelanguage.googleapis.com',
        azureApiVersion: '2024-02-01',
        requestTimeoutMs: 30_000
      }
    ) do |data|
      global_settings = data.global_settings
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
    with_data(
      global_settings: {
        welcomeViewCompleted: true,
        customPrompt: 'Custom prompt text',
        defaultTerminalProfile: 'bash',
        telemetrySetting: 'disabled',
        ocaMode: 'full',
        clineVersion: '1.0.0',
        lastShownAnnouncementId: 'announce-123',
        vscodeTerminalExecutionMode: 'integrated',
        isNewUser: false,
        mcpDisplayMode: 'list',
        lastDismissedInfoBannerVersion: 5,
        lastDismissedModelBannerVersion: 3
      }
    ) do |data|
      global_settings = data.global_settings
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
    with_data(
      global_settings: {
        remoteRulesToggles: { 'rule1' => true, 'rule2' => false },
        remoteWorkflowToggles: { 'workflow1' => true },
        globalWorkflowToggles: { 'workflow_a' => false, 'workflow_b' => true },
        globalClineRulesToggles: { 'core_rule' => true },
        remoteSkillsToggles: { 'skill_x' => false, 'skill_y' => true },
        globalSkillsToggles: { 'default_skill' => true }
      }
    ) do |data|
      global_settings = data.global_settings
      expect(global_settings).not_to be_nil
      expect(global_settings.remote_rules_toggles.to_h).to eq({ 'rule1' => true, 'rule2' => false })
      expect(global_settings.remote_rules_toggles['rule1']).to be true
      expect(global_settings.remote_rules_toggles['rule2']).to be false
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
        clineWebToolsEnabled: true,
        focusChainSettings: {
          enabled: true,
          remindClineInterval: 5
        }
      }
      with_data(global_settings: settings_hash) do |data1|
        settings1 = data1.global_settings
        with_data(global_settings: settings_hash) do |data2|
          settings2 = data2.global_settings
          # Settings are from different data directories but have identical content
          expect(settings1).not_to equal(settings2) # Different instances
          expect(settings1).to eq(settings2)
        end
      end
    end

    it 'returns false when 2 global settings have different attributes' do
      with_data(global_settings: { clineWebToolsEnabled: true }) do |data1|
        with_data(global_settings: { clineWebToolsEnabled: false }) do |data2|
          expect(data1.global_settings).not_to eq(data2.global_settings)
        end
      end
    end

    it 'returns false when 2 global settings have different nested attributes' do
      with_data(global_settings: { focusChainSettings: { enabled: true } }) do |data1|
        with_data(global_settings: { focusChainSettings: { enabled: false } }) do |data2|
          expect(data1.global_settings).not_to eq(data2.global_settings)
        end
      end
    end

    it 'returns false when 2 global settings have unknown attributes' do
      with_data(global_settings: { focusChainSettings: { unknownAttribute: 1 } }) do |data1|
        with_data(global_settings: { focusChainSettings: { unknownAttribute: 2 } }) do |data2|
          expect(data1.global_settings).not_to eq(data2.global_settings)
        end
      end
    end
  end
end
