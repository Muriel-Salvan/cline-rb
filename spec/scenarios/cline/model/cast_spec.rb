describe Cline::Model, '#cast' do
  # @return [Cline::Model] A model instance to be tested
  attr_reader :model

  around do |example|
    with_data(
      cline_models: { 'test-model' => {} }
    ) do |data|
      @model = data.cline_models['test-model']
      example.run
    end
  end

  it 'initializes thinking_config from Hash' do
    model.thinking_config = { max_budget: 2000 }
    expect(model.thinking_config.max_budget).to eq 2000
  end
end
