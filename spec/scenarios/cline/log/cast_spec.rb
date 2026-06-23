describe Cline::Log, '#cast' do
  # @return [Cline::Log] A log entry instance to be tested
  attr_reader :log_entry

  around do |example|
    with_logs(lines: [{}]) do |logs|
      @log_entry = logs.first
      example.run
    end
  end

  it 'initializes properties from Hash' do
    log_entry.properties = {
      ulid: 'test-ulid',
      api_provider: 'cline',
      agent_id: 'agent-1',
      is_subagent: true,
      mode: 'act',
      tokens_in: 100,
      tokens_out: 50,
      total_cost: 0.001,
      duration_ms: 500
    }
    expect(log_entry.properties.ulid).to eq 'test-ulid'
    expect(log_entry.properties.api_provider).to eq 'cline'
    expect(log_entry.properties.agent_id).to eq 'agent-1'
    expect(log_entry.properties.is_subagent).to be true
    expect(log_entry.properties.mode).to eq 'act'
    expect(log_entry.properties.tokens_in).to eq 100
    expect(log_entry.properties.tokens_out).to eq 50
    expect(log_entry.properties.total_cost).to eq 0.001
    expect(log_entry.properties.duration_ms).to eq 500
  end

  it 'initializes err with nested Error, ApiError, and ErrorCause from Hash' do
    log_entry.err = {
      type: 'AI_RetryError',
      message: 'API call failed after 3 retries',
      name: 'AI_APICallError',
      reason: 'maxRetriesExceeded',
      errors: [
        {
          type: 'AI_APICallError',
          message: 'Connection refused',
          name: 'AI_APICallError',
          url: 'https://api.example.com',
          is_retryable: true,
          cause: { code: 'ConnectionRefused', path: '/v1/chat' }
        }
      ],
      aggregate_errors: [
        { type: 'AI_APICallError', message: 'Network timeout', name: 'AI_APICallError', url: 'https://api.example.com' }
      ],
      last_error: {
        type: 'AI_APICallError',
        message: 'Final error',
        name: 'AI_APICallError',
        cause: { code: 'ECONNRESET', errno: 104 }
      }
    }
    expect(log_entry.err.type).to eq 'AI_RetryError'
    expect(log_entry.err.message).to eq 'API call failed after 3 retries'
    expect(log_entry.err.reason).to eq 'maxRetriesExceeded'

    expect(log_entry.err.errors.size).to eq 1
    api_error = log_entry.err.errors[0]
    expect(api_error.message).to eq 'Connection refused'
    expect(api_error.is_retryable).to be true

    expect(api_error.cause.code).to eq 'ConnectionRefused'
    expect(api_error.cause.path).to eq '/v1/chat'

    expect(log_entry.err.aggregate_errors.size).to eq 1
    expect(log_entry.err.aggregate_errors[0].message).to eq 'Network timeout'

    expect(log_entry.err.last_error.message).to eq 'Final error'
    expect(log_entry.err.last_error.cause.code).to eq 'ECONNRESET'
    expect(log_entry.err.last_error.cause.errno).to eq 104
  end
end
