describe Cline::Data, '#logs' do
  it 'returns no logs when no log file exists in data directory' do
    with_data do |data|
      expect(data.logs).to be_nil
    end
  end

  it 'initializes logs when data is initialized with create option' do
    with_data(create: true) do |data|
      expect(data.logs).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'logs', 'cline.log'))).to be true
    end
  end

  it 'initializes logs when create option is given' do
    with_data do |data|
      expect(data.logs(create: true)).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'logs', 'cline.log'))).to be true
    end
  end

  it 'returns Logs instance with correct content when log file exists' do
    with_data(
      logs: [
        { msg: 'First log' },
        { msg: 'Second log' }
      ]
    ) do |data|
      logs = data.logs
      expect(logs.size).to eq 2
      expect(logs[0].msg).to eq 'First log'
      expect(logs[1].msg).to eq 'Second log'
    end
  end

  it 'validates that all attributes of logs are correctly read' do
    with_data(
      logs: [
        {
          level: 30,
          time: '2026-01-01T00:00:00.000Z',
          pid: 12_345,
          hostname: 'test-host',
          name: 'test.logger',
          msg: 'Test message',
          component: 'main',
          interactive: true,
          cwd: '/home/user/project',
          reason: 'test reason',
          backendMode: 'auto',
          forceLocalBackend: true,
          telemetrySink: 'TelemetryLoggerSink',
          event: 'test.event',
          properties: {
            ulid: '01J7XYZ8K9ABCDEFGHIJKLMNOP',
            api_provider: 'cline',
            agent_id: 'agent-1',
            agent_kind: 'team_lead',
            conversation_id: 'conv-123',
            is_subagent: true,
            team_id: 'team-42',
            team_name: 'alpha-team',
            team_role: 'lead',
            lead_agent_id: 'lead-agent-1',
            provider: 'deepseek',
            model_id: 'deepseek/deepseek-v4-flash',
            model: 'deepseek/deepseek-v4-flash',
            source: 'user',
            mode: 'act',
            timestamp: '2026-01-01T00:00:00.000Z',
            run_id: 'run-001',
            status: 'completed',
            iteration: 3,
            event_type: 'turn-started',
            session_id: 'session-abc',
            enable_tools: true,
            enable_spawn_agent: false,
            enable_agent_teams: true,
            tokens_in: 500,
            tokens_out: 1000,
            total_cost: 0.015,
            cache_read_tokens: 50,
            cache_write_tokens: 10,
            tool: 'use_mcp_tool',
            success: true,
            duration_ms: 1500,
            provider_id: 'provider-xyz',
            root_count: 2,
            vcs_types: ['git'],
            is_multi_root: true,
            has_git: true,
            has_mercurial: false,
            init_duration_ms: 250.5,
            feature_flag_enabled: true,
            extension_version: '3.0.7',
            cline_type: 'cli',
            platform: 'vscode',
            platform_version: '1.96.0',
            os_type: 'win32',
            os_version: 'Windows 11 Pro',
            distinct_id: 'distinct-001',
            restored_from_persistence: false
          }
        }
      ]
    ) do |data|
      log = data.logs[0]
      expect(log.level).to eq 30
      expect(log.time).to eq '2026-01-01T00:00:00.000Z'
      expect(log.pid).to eq 12_345
      expect(log.hostname).to eq 'test-host'
      expect(log.name).to eq 'test.logger'
      expect(log.msg).to eq 'Test message'
      expect(log.component).to eq 'main'
      expect(log.interactive).to be true
      expect(log.has_prompt).to be_nil
      expect(log.cwd).to eq '/home/user/project'
      expect(log.reason).to eq 'test reason'
      expect(log.backend_mode).to eq 'auto'
      expect(log.force_local_backend).to be true
      expect(log.telemetry_sink).to eq 'TelemetryLoggerSink'
      expect(log.event).to eq 'test.event'
      expect(log.properties.ulid).to eq '01J7XYZ8K9ABCDEFGHIJKLMNOP'
      expect(log.properties.api_provider).to eq 'cline'
      expect(log.properties.agent_id).to eq 'agent-1'
      expect(log.properties.agent_kind).to eq 'team_lead'
      expect(log.properties.conversation_id).to eq 'conv-123'
      expect(log.properties.is_subagent).to be true
      expect(log.properties.team_id).to eq 'team-42'
      expect(log.properties.team_name).to eq 'alpha-team'
      expect(log.properties.team_role).to eq 'lead'
      expect(log.properties.lead_agent_id).to eq 'lead-agent-1'
      expect(log.properties.provider).to eq 'deepseek'
      expect(log.properties.model_id).to eq 'deepseek/deepseek-v4-flash'
      expect(log.properties.model).to eq 'deepseek/deepseek-v4-flash'
      expect(log.properties.source).to eq 'user'
      expect(log.properties.mode).to eq 'act'
      expect(log.properties.timestamp).to eq '2026-01-01T00:00:00.000Z'
      expect(log.properties.run_id).to eq 'run-001'
      expect(log.properties.status).to eq 'completed'
      expect(log.properties.iteration).to eq 3
      expect(log.properties.event_type).to eq 'turn-started'
      expect(log.properties.session_id).to eq 'session-abc'
      expect(log.properties.enable_tools).to be true
      expect(log.properties.enable_spawn_agent).to be false
      expect(log.properties.enable_agent_teams).to be true
      expect(log.properties.tokens_in).to eq 500
      expect(log.properties.tokens_out).to eq 1000
      expect(log.properties.total_cost).to eq 0.015
      expect(log.properties.cache_read_tokens).to eq 50
      expect(log.properties.cache_write_tokens).to eq 10
      expect(log.properties.tool).to eq 'use_mcp_tool'
      expect(log.properties.success).to be true
      expect(log.properties.duration_ms).to eq 1500
      expect(log.properties.provider_id).to eq 'provider-xyz'
      expect(log.properties.root_count).to eq 2
      expect(log.properties.vcs_types).to eq ['git']
      expect(log.properties.is_multi_root).to be true
      expect(log.properties.has_git).to be true
      expect(log.properties.has_mercurial).to be false
      expect(log.properties.init_duration_ms).to eq 250.5
      expect(log.properties.feature_flag_enabled).to be true
      expect(log.properties.extension_version).to eq '3.0.7'
      expect(log.properties.cline_type).to eq 'cli'
      expect(log.properties.platform).to eq 'vscode'
      expect(log.properties.platform_version).to eq '1.96.0'
      expect(log.properties.os_type).to eq 'win32'
      expect(log.properties.os_version).to eq 'Windows 11 Pro'
      expect(log.properties.distinct_id).to eq 'distinct-001'
      expect(log.properties.restored_from_persistence).to be false
    end
  end

  it 'ignores unknown attributes from logs and does not include them in the Log object' do
    with_data(
      logs: [
        {
          msg: 'Known message',
          unknownField: 'should be ignored',
          properties: {
            unknownProperty: 'should be ignored in nested properties too'
          }
        }
      ]
    ) do |data|
      log = data.logs[0]
      expect(log.msg).to eq 'Known message'
      expect(log.respond_to?(:unknown_field)).to be false
      expect(log.respond_to?(:unknownField)).to be false
      expect(log.properties.respond_to?(:unknown_property)).to be false
      expect(log.properties.respond_to?(:unknownProperty)).to be false
    end
  end

  it 'handles non-JSON log entries properly by returning them as plain strings' do
    with_data(
      logs: [
        { msg: 'First JSON log' },
        'Plain string log entry',
        { msg: 'Second JSON log' },
        'Another plain string entry'
      ]
    ) do |data|
      logs = data.logs
      expect(logs.size).to eq 4
      expect(logs[0].msg).to eq 'First JSON log'
      expect(logs[1]).to eq 'Plain string log entry'
      expect(logs[2].msg).to eq 'Second JSON log'
      expect(logs[3]).to eq 'Another plain string entry'
    end
  end
end
