describe Cline::Data, '#cline_models' do
  it 'returns nil when no cline_models.json file exists' do
    with_data(cline_models: nil) do |data|
      expect(data.cline_models).to be_nil
    end
  end

  it 'reads all attributes of the models' do
    with_data(
      cline_models: {
        'test/model-1' => {
          'name' => 'Test Model 1',
          'maxTokens' => 1000,
          'contextWindow' => 100_000,
          'supportsImages' => true,
          'supportsPromptCache' => false,
          'inputPrice' => 1.25,
          'outputPrice' => 2.5,
          'cacheReadsPrice' => 0.2,
          'description' => 'Test model description',
          'thinkingConfig' => {
            'maxBudget' => 6000
          }
        }
      }
    ) do |data|
      models = data.cline_models
      expect(models.size).to eq 1
      model = models['test/model-1']
      expect(model.name).to eq 'Test Model 1'
      expect(model.max_tokens).to eq 1000
      expect(model.context_window).to eq 100_000
      expect(model.supports_images).to be true
      expect(model.supports_prompt_cache).to be false
      expect(model.input_price).to eq 1.25
      expect(model.output_price).to eq 2.5
      expect(model.cache_reads_price).to eq 0.2
      expect(model.description).to eq 'Test model description'
      expect(model.thinking_config).to be_a(Cline::Model::ThinkingConfig)
      expect(model.thinking_config.max_budget).to eq 6000
    end
  end

  it 'ignores extra unknown parameters from cline_models.json file' do
    with_data(
      cline_models: {
        'test/model-1' => {
          'name' => 'Test Model 1',
          'maxTokens' => 1000,
          'this_is_an_unknown_parameter' => 'should be ignored'
        }
      }
    ) do |data|
      models = data.cline_models
      # Verify valid attributes are still correctly loaded
      expect(models['test/model-1'].name).to eq 'Test Model 1'
      expect(models['test/model-1'].max_tokens).to eq 1000
      # Verify unknown parameters are not present on the object
      expect(models['test/model-1']).not_to respond_to(:this_is_an_unknown_parameter)
    end
  end

  it 'loads multiple models' do
    with_data(
      cline_models: {
        'test/model-1' => { 'name' => 'Test Model 1' },
        'test/model-2' => { 'name' => 'Test Model 2' },
        'test/model-3' => { 'name' => 'Test Model 3' }
      }
    ) do |data|
      models = data.cline_models
      expect(models.size).to eq 3
      expect(models.keys).to contain_exactly('test/model-1', 'test/model-2', 'test/model-3')
      expect(models['test/model-1'].name).to eq 'Test Model 1'
      expect(models['test/model-2'].name).to eq 'Test Model 2'
      expect(models['test/model-3'].name).to eq 'Test Model 3'
    end
  end

  describe '#==' do
    it 'returns true when 2 data instances have the same models' do
      models_hash = {
        'test/model-1' => { 'name' => 'Test Model 1' },
        'test/model-2' => { 'name' => 'Test Model 2' }
      }
      with_data(cline_models: models_hash) do |data1|
        with_data(cline_models: models_hash) do |data2|
          # Data instances are from different directories but have identical models
          expect(data1).not_to equal(data2) # Different instances
          expect(data1).to eq(data2)
          expect(data1.cline_models).not_to equal(data2.cline_models)
          expect(data1.cline_models).to eq(data2.cline_models)
        end
      end
    end

    it 'returns false when 2 data instances have different models' do
      with_data(cline_models: { 'test/model-1' => { 'name' => 'Test Model 1' } }) do |data1|
        with_data(cline_models: { 'test/model-1' => { 'name' => 'Different Model' } }) do |data2|
          expect(data1).not_to eq(data2)
          expect(data1.cline_models).not_to eq(data2.cline_models)
        end
      end
    end
  end
end
