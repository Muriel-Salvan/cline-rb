describe Cline::Message, '#==' do
  it 'returns true for messages with same content even with different cline_models instances' do
    message_hash = {
      ts: 123_456,
      type: 'say',
      say: 'text',
      text: 'Hello world',
      model_info: {
        provider_id: 'test',
        model_id: 'test/model',
        mode: 'act'
      }
    }
    with_task(
      messages: [message_hash],
      cline_models: { 'test/model' => { 'name' => 'Test Model 1', 'contextWindow' => 128_000 } }
    ) do |task1|
      with_task(
        name: 'other-task',
        messages: [message_hash],
        cline_models: { 'test/model' => { 'name' => 'Test Model 2', 'contextWindow' => 256_000 } }
      ) do |task2|
        message1 = task1.messages.first
        message2 = task2.messages.first
        expect(message1.cline_models).not_to equal(message2.cline_models)
        expect(message1).to eq(message2)
      end
    end
  end
end
