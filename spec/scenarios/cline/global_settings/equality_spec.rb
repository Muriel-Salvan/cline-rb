describe Cline::GlobalSettings, '#==' do
  it 'returns true when 2 global settings from different data directories have the same content' do
    settings_hash = {
      clineWebToolsEnabled: true,
      focusChainSettings: {
        enabled: true,
        remindClineInterval: 5
      }
    }
    with_global_settings(attributes: settings_hash) do |settings1|
      with_global_settings(attributes: settings_hash) do |settings2|
        # Settings are from different data directories but have identical content
        expect(settings1).not_to equal(settings2) # Different instances
        expect(settings1).to eq(settings2)
      end
    end
  end

  it 'returns false when 2 global settings have different attributes' do
    with_global_settings(attributes: { clineWebToolsEnabled: true }) do |settings1|
      with_global_settings(attributes: { clineWebToolsEnabled: false }) do |settings2|
        expect(settings1).not_to eq(settings2)
      end
    end
  end

  it 'returns false when 2 global settings have different nested attributes' do
    with_global_settings(attributes: { focusChainSettings: { enabled: true } }) do |settings1|
      with_global_settings(attributes: { focusChainSettings: { enabled: false } }) do |settings2|
        expect(settings1).not_to eq(settings2)
      end
    end
  end

  it 'returns false when 2 global settings have unknown attributes' do
    with_global_settings(attributes: { focusChainSettings: { unknownAttribute: 1 } }) do |settings1|
      with_global_settings(attributes: { focusChainSettings: { unknownAttribute: 2 } }) do |settings2|
        expect(settings1).not_to eq(settings2)
      end
    end
  end
end
