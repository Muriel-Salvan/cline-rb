describe Cline::Session, '#data' do
  it 'returns nil when no json file exists in session directory' do
    with_session(data: nil) do |session|
      expect(session.data).to be_nil
    end
  end

  it 'initializes data when session is initialized with create option' do
    with_session(data: nil, create: true) do |session|
      session_data = session.data
      expect(session_data).not_to be_nil
      expect(File.exist?(File.join(session.dir, 'test-session.json'))).to be true
    end
  end

  it 'initializes data when create option is given' do
    with_session(data: nil) do |session|
      session_data = session.data(create: true)
      expect(session_data).not_to be_nil
      expect(File.exist?(File.join(session.dir, 'test-session.json'))).to be true
    end
  end

  it 'reads all attributes of the session data' do
    with_session(
      data: {
        version: 1,
        session_id: 'test-session-123',
        source: 'cli',
        pid: 12_345,
        started_at: '2026-05-18T19:40:19.818Z',
        ended_at: '2026-05-18T19:40:57.414Z',
        exit_code: 0,
        status: 'completed',
        interactive: false,
        provider: 'cline',
        model: 'deepseek/deepseek-v4-flash',
        cwd: '/test/dir',
        workspace_root: '/test/workspace',
        team_name: 'test-team',
        enable_tools: true,
        enable_spawn: true,
        enable_teams: true,
        prompt: 'Test prompt',
        messages_path: 'path/to/messages.json',
        metadata: {
          title: 'Test session',
          checkpoint: {
            latest: {
              ref: '0d07d92af208720d4fe3636d18bd4d9fb6688362',
              createdAt: 1_779_133_220_819,
              runCount: 1,
              kind: 'stash'
            },
            history: [
              {
                ref: '0d07d92af208720d4fe3636d18bd4d9fb6688362',
                createdAt: 1_779_133_220_819,
                runCount: 1,
                kind: 'stash'
              }
            ]
          },
          totalCost: 0.0001391152,
          aggregatedAgentsCost: 0.0001391152,
          usage: {
            inputTokens: 10_238,
            outputTokens: 270,
            cacheReadTokens: 9_984,
            cacheWriteTokens: 0,
            totalCost: 0.0001391152
          },
          aggregateUsage: {
            inputTokens: 10_238,
            outputTokens: 270,
            cacheReadTokens: 9_984,
            cacheWriteTokens: 0,
            totalCost: 0.0001391152
          }
        }
      }
    ) do |session|
      session_data = session.data
      expect(session_data.session_id).to eq 'test-session-123'
      expect(session_data.source).to eq 'cli'
      expect(session_data.pid).to eq 12_345
      expect(session_data.status).to eq 'completed'
      expect(session_data.interactive).to be false
      expect(session_data.provider).to eq 'cline'
      expect(session_data.model).to eq 'deepseek/deepseek-v4-flash'
      expect(session_data.cwd).to eq '/test/dir'
      expect(session_data.workspace_root).to eq '/test/workspace'
      expect(session_data.team_name).to eq 'test-team'
      expect(session_data.enable_tools).to be true
      expect(session_data.enable_spawn).to be true
      expect(session_data.enable_teams).to be true
      expect(session_data.prompt).to eq 'Test prompt'
      expect(session_data.messages_path).to eq 'path/to/messages.json'
      expect(session_data.metadata).not_to be_nil
      expect(session_data.metadata.title).to eq 'Test session'
      expect(session_data.metadata.checkpoint).not_to be_nil
      expect(session_data.metadata.checkpoint.latest).not_to be_nil
      expect(session_data.metadata.checkpoint.latest.ref).to eq '0d07d92af208720d4fe3636d18bd4d9fb6688362'
      expect(session_data.metadata.checkpoint.latest.created_at).to eq 1_779_133_220_819
      expect(session_data.metadata.checkpoint.latest.run_count).to eq 1
      expect(session_data.metadata.checkpoint.latest.kind).to eq 'stash'
      expect(session_data.metadata.checkpoint.history.size).to eq 1
      expect(session_data.metadata.checkpoint.history[0].ref).to eq '0d07d92af208720d4fe3636d18bd4d9fb6688362'
      expect(session_data.metadata.checkpoint.history[0].created_at).to eq 1_779_133_220_819
      expect(session_data.metadata.checkpoint.history[0].run_count).to eq 1
      expect(session_data.metadata.checkpoint.history[0].kind).to eq 'stash'
      expect(session_data.metadata.total_cost).to eq 0.0001391152
      expect(session_data.metadata.aggregated_agents_cost).to eq 0.0001391152
      expect(session_data.metadata.usage).not_to be_nil
      expect(session_data.metadata.usage.input_tokens).to eq 10_238
      expect(session_data.metadata.usage.output_tokens).to eq 270
      expect(session_data.metadata.usage.cache_read_tokens).to eq 9_984
      expect(session_data.metadata.usage.cache_write_tokens).to eq 0
      expect(session_data.metadata.usage.total_cost).to eq 0.0001391152
      expect(session_data.metadata.aggregate_usage).not_to be_nil
      expect(session_data.metadata.aggregate_usage.input_tokens).to eq 10_238
      expect(session_data.metadata.aggregate_usage.output_tokens).to eq 270
      expect(session_data.metadata.aggregate_usage.cache_read_tokens).to eq 9_984
      expect(session_data.metadata.aggregate_usage.cache_write_tokens).to eq 0
      expect(session_data.metadata.aggregate_usage.total_cost).to eq 0.0001391152
    end
  end

  it 'ignores extra unknown parameters from the json file' do
    with_session(
      data: {
        session_id: 'test',
        source: 'cli',
        this_is_an_unknown_parameter: 'should be ignored',
        another_extra_field: 12_345
      }
    ) do |session|
      session_data = session.data
      # Verify valid attributes are still correctly loaded
      expect(session_data.session_id).to eq 'test'
      expect(session_data.source).to eq 'cli'
      # Verify unknown parameters are not present on the object
      expect(session_data).not_to respond_to(:this_is_an_unknown_parameter)
      expect(session_data).not_to respond_to(:thisIsAnUnknownParameter)
      expect(session_data).not_to respond_to(:another_extra_field)
      expect(session_data).not_to respond_to(:anotherExtraField)
    end
  end

  it 'raises Errno::EACCES after retrying 3 times when the file cannot be read' do
    with_session(
      data: {
        session_id: 'test',
        source: 'cli'
      }
    ) do |session|
      read_call_count = 0
      allow(File).to(receive(:read).with(File.join(session.dir, 'test-session.json'))) do |*_args|
        read_call_count += 1
        raise Errno::EACCES
      end
      expect { session.data }.to raise_error(Errno::EACCES)
      expect(read_call_count).to eq 4
    end
  end

  it 'recovers from a temporary read error and reads the file successfully on retry' do
    with_session(
      data: {
        session_id: 'test',
        source: 'cli'
      }
    ) do |session|
      read_call_count = 0
      original_read = File.method(:read)
      allow(File).to(receive(:read).with(File.join(session.dir, 'test-session.json'))) do |*args|
        read_call_count += 1
        raise Errno::EACCES if read_call_count == 1

        original_read.call(*args)
      end

      session_data = session.data
      expect(read_call_count).to eq 2
      expect(session_data).not_to be_nil
      expect(session_data.session_id).to eq 'test'
    end
  end

  it 'raises JSON::ParserError after retrying 3 times when the file contains invalid JSON' do
    with_session(
      data: {
        session_id: 'test',
        source: 'cli'
      }
    ) do |session|
      read_call_count = 0
      allow(File).to(receive(:read).with(File.join(session.dir, 'test-session.json'))) do |*_args|
        read_call_count += 1
        '{invalid json content'
      end
      expect { session.data }.to raise_error(JSON::ParserError)
      expect(read_call_count).to eq 4
    end
  end

  it 'recovers from invalid JSON and parses the file successfully on retry' do
    with_session(
      data: {
        session_id: 'test',
        source: 'cli'
      }
    ) do |session|
      read_call_count = 0
      original_read = File.method(:read)
      allow(File).to(receive(:read).with(File.join(session.dir, 'test-session.json'))) do |*args|
        read_call_count += 1
        if read_call_count == 1
          '{invalid json content'
        else
          original_read.call(*args)
        end
      end

      session_data = session.data
      expect(read_call_count).to eq 2
      expect(session_data).not_to be_nil
      expect(session_data.session_id).to eq 'test'
    end
  end
end
