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
    message.metrics = { input_tokens: 10, output_tokens: 20, cache_read_tokens: 5, cache_write_tokens: 2, cost: 0.001 }
    expect(message.metrics.input_tokens).to eq 10
    expect(message.metrics.output_tokens).to eq 20
    expect(message.metrics.cache_read_tokens).to eq 5
    expect(message.metrics.cache_write_tokens).to eq 2
    expect(message.metrics.cost).to eq 0.001
  end

  it 'initializes content blocks with nested ToolUseInput from Hash' do
    message.content = [
      {
        type: 'tool_use',
        id: 'tool-1',
        name: 'ask_question',
        input: {
          question: 'Continue?',
          options: %w[Yes No],
          path: '/path/to/file',
          new_text: 'new content',
          old_text: 'old content',
          commands: ['echo hello', 'echo world'],
          files: [{ path: '/path/to/file1' }, { path: '/path/to/file2' }]
        }
      }
    ]
    expect(message.content.size).to eq 1
    expect(message.content[0].type).to eq 'tool_use'
    expect(message.content[0].id).to eq 'tool-1'
    expect(message.content[0].name).to eq 'ask_question'
    expect(message.content[0].input.question).to eq 'Continue?'
    expect(message.content[0].input.options.to_a).to eq %w[Yes No]
    expect(message.content[0].input.path).to eq '/path/to/file'
    expect(message.content[0].input.new_text).to eq 'new content'
    expect(message.content[0].input.old_text).to eq 'old content'
    expect(message.content[0].input.commands.to_a).to eq ['echo hello', 'echo world']
    expect(message.content[0].input.files.to_a.size).to eq 2
    expect(message.content[0].input.files[0].path).to eq '/path/to/file1'
    expect(message.content[0].input.files[1].path).to eq '/path/to/file2'
  end

  it 'initializes options given as a String' do
    message.content = [
      {
        type: 'tool_use',
        id: 'tool-1',
        name: 'ask_question',
        input: { question: 'Continue?', options: 'Yes' }
      }
    ]
    expect(message.content[0].input.question).to eq 'Continue?'
    expect(message.content[0].input.options).to eq 'Yes'
  end

  it 'initializes thinking content blocks from Hash' do
    message.content = [
      { type: 'thinking', thinking: 'Let me think about this...' }
    ]
    expect(message.content.size).to eq 1
    expect(message.content[0].type).to eq 'thinking'
    expect(message.content[0].thinking).to eq 'Let me think about this...'
  end

  it 'initializes a tool result content given as a String from Hash' do
    message.content = [
      { type: 'tool_result', tool_use_id: 'tool-1', content: 'File content here' }
    ]
    expect(message.content.size).to eq 1
    expect(message.content[0].type).to eq 'tool_result'
    expect(message.content[0].tool_use_id).to eq 'tool-1'
    expect(message.content[0].content).to eq 'File content here'
  end

  it 'initializes a tool result content given as a list of entries from Hash' do
    message.content = [
      {
        type: 'tool_result',
        tool_use_id: 'tool-1',
        content: [{ query: 'ls', result: 'file.txt', success: true }]
      }
    ]
    expect(message.content.size).to eq 1
    expect(message.content[0].content.size).to eq 1
    expect(message.content[0].content[0].query).to eq 'ls'
    expect(message.content[0].content[0].result).to eq 'file.txt'
    expect(message.content[0].content[0].success).to be true
  end
end
