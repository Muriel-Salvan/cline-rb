describe Cline::SessionData, '#cast' do
  # @return [Cline::SessionData] A session data instance to be tested
  attr_reader :session_data

  around do |example|
    with_session(
      name: 'test-session',
      create: true,
      data: {}
    ) do |session|
      @session_data = session.data
      example.run
    end
  end

  it 'initializes metadata with nested Checkpoint, CheckpointEntry, and Usage from Hash' do
    session_data.metadata = {
      title: 'Test Session',
      total_cost: 0.05,
      aggregated_agents_cost: 0.01,
      checkpoint: {
        latest: { ref: 'abc123', created_at: 1_000_000, run_count: 3, kind: 'stash' },
        history: [
          { ref: 'def456', created_at: 900_000, run_count: 2, kind: 'stash' },
          { ref: 'ghi789', created_at: 800_000, run_count: 1, kind: 'stash' }
        ]
      },
      usage: { input_tokens: 100, output_tokens: 50, cache_read_tokens: 10, cache_write_tokens: 5, total_cost: 0.02 },
      aggregate_usage: { input_tokens: 200, output_tokens: 100, cache_read_tokens: 20, cache_write_tokens: 10, total_cost: 0.04 }
    }
    expect(session_data.metadata.title).to eq 'Test Session'
    expect(session_data.metadata.total_cost).to eq 0.05
    expect(session_data.metadata.aggregated_agents_cost).to eq 0.01

    checkpoint = session_data.metadata.checkpoint
    expect(checkpoint.latest.ref).to eq 'abc123'
    expect(checkpoint.latest.created_at).to eq 1_000_000
    expect(checkpoint.latest.run_count).to eq 3
    expect(checkpoint.latest.kind).to eq 'stash'

    expect(checkpoint.history.size).to eq 2
    expect(checkpoint.history[0].ref).to eq 'def456'
    expect(checkpoint.history[0].created_at).to eq 900_000
    expect(checkpoint.history[1].ref).to eq 'ghi789'

    expect(session_data.metadata.usage.input_tokens).to eq 100
    expect(session_data.metadata.usage.output_tokens).to eq 50
    expect(session_data.metadata.usage.cache_read_tokens).to eq 10
    expect(session_data.metadata.usage.cache_write_tokens).to eq 5
    expect(session_data.metadata.usage.total_cost).to eq 0.02

    expect(session_data.metadata.aggregate_usage.input_tokens).to eq 200
  end
end
