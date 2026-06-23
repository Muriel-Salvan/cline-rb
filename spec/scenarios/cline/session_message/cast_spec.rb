describe Cline::SessionMessage, '#cast' do
  # @return [Cline::SessionMessage] A session message instance to be tested
  attr_reader :message

  around do |example|
    with_session(
      name: 'test-session',
      messages: { messages: [{}] },
      create: true
    ) do |session|
      @message = session.messages.first
      example.run
    end
  end

  it 'initializes model_info from Hash' do
    message.model_info = { id: 'test/model', provider: 'test', family: 'test-family' }
    expect(message.model_info.id).to eq 'test/model'
    expect(message.model_info.provider).to eq 'test'
    expect(message.model_info.family).to eq 'test-family'
  end

  it 'initializes metrics from Hash' do
    message.metrics = { input_tokens: 10, output_tokens: 20, cost: 0.001 }
    expect(message.metrics.input_tokens).to eq 10
    expect(message.metrics.output_tokens).to eq 20
    expect(message.metrics.cost).to eq 0.001
  end

  it 'initializes content blocks with nested ToolUseInput from Hash' do
    message.content = [
      { type: 'tool_use', id: 'tool-1', name: 'ask_question', input: { question: 'Continue?', options: %w[Yes No] } }
    ]
    expect(message.content.size).to eq 1
    expect(message.content[0].type).to eq 'tool_use'
    expect(message.content[0].id).to eq 'tool-1'
    expect(message.content[0].name).to eq 'ask_question'
    expect(message.content[0].input.question).to eq 'Continue?'
    expect(message.content[0].input.options.to_a).to eq %w[Yes No]
  end
end
