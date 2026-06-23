describe Cline::TaskMessage, '#cast' do
  # @return [Cline::TaskMessage] A task message instance to be tested
  attr_reader :message

  around do |example|
    with_task(
      messages: [{}]
    ) do |task|
      @message = task.messages.first
      example.run
    end
  end

  it 'initializes model_info from Hash' do
    message.model_info = { provider_id: 'test', model_id: 'test/model', mode: 'act' }
    expect(message.model_info.provider_id).to eq 'test'
    expect(message.model_info.model_id).to eq 'test/model'
    expect(message.model_info.mode).to eq 'act'
  end
end
