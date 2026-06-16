describe Cline::GlobalSettings, '#==' do
  it 'returns true when 2 global settings from different data directories have the same content' do
    settings_hash = {
      autoUpdateEnabled: true,
      telemetryOptOut: false,
      disabledTools: %w[tool1 tool2]
    }
    with_global_settings(global_settings: settings_hash) do |settings1|
      with_global_settings(global_settings: settings_hash) do |settings2|
        # Settings are from different data directories but have identical content
        expect(settings1).not_to equal(settings2) # Different instances
        expect(settings1).to eq(settings2)
      end
    end
  end

  it 'returns false when 2 global settings have different auto_update_enabled' do
    with_global_settings(global_settings: { autoUpdateEnabled: true }) do |settings1|
      with_global_settings(global_settings: { autoUpdateEnabled: false }) do |settings2|
        expect(settings1).not_to eq(settings2)
      end
    end
  end

  it 'returns false when 2 global settings have different telemetry_opt_out' do
    with_global_settings(global_settings: { telemetryOptOut: true }) do |settings1|
      with_global_settings(global_settings: { telemetryOptOut: false }) do |settings2|
        expect(settings1).not_to eq(settings2)
      end
    end
  end

  it 'returns false when 2 global settings have different disabled_tools' do
    with_global_settings(global_settings: { disabledTools: %w[tool1] }) do |settings1|
      with_global_settings(global_settings: { disabledTools: %w[tool2] }) do |settings2|
        expect(settings1).not_to eq(settings2)
      end
    end
  end

  it 'returns false when 2 global settings have different unknown attributes' do
    with_global_settings(global_settings: { unknownAttribute: 1 }) do |settings1|
      with_global_settings(global_settings: { unknownAttribute: 2 }) do |settings2|
        expect(settings1).not_to eq(settings2)
      end
    end
  end
end
