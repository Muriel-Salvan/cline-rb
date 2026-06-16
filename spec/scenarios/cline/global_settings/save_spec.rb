describe Cline::GlobalSettings, '#save' do
  it 'persists modified attributes to the global-settings.json file' do
    with_global_settings(
      global_settings: {
        autoUpdateEnabled: true,
        telemetryOptOut: false,
        disabledTools: %w[tool1 tool2]
      }
    ) do |settings|
      settings.auto_update_enabled = false
      settings.telemetry_opt_out = true
      settings.disabled_tools = %w[tool3]
      settings.save
      expect(JSON.parse(File.read(File.join(settings.dir, 'settings/global-settings.json')))).to eq(
        'autoUpdateEnabled' => false,
        'telemetryOptOut' => true,
        'disabledTools' => %w[tool3]
      )
    end
  end

  it 'persists unknown attributes to the global-settings.json file' do
    with_global_settings(
      global_settings: {
        autoUpdateEnabled: true,
        telemetryOptOut: false,
        unknownAttribute: 'Unknown value'
      }
    ) do |settings|
      settings.auto_update_enabled = false
      settings.save
      expect(JSON.parse(File.read(File.join(settings.dir, 'settings/global-settings.json')))).to eq(
        'autoUpdateEnabled' => false,
        'disabledTools' => [],
        'telemetryOptOut' => false,
        'unknownAttribute' => 'Unknown value'
      )
    end
  end

  it 'persists a newly instantiated global settings file' do
    with_global_settings(global_settings: nil, create: true) do |settings|
      settings.auto_update_enabled = true
      settings.telemetry_opt_out = false
      settings.disabled_tools = %w[tool1 tool2]
      settings.save
      expect(JSON.parse(File.read(File.join(settings.dir, 'settings/global-settings.json')))).to eq(
        'autoUpdateEnabled' => true,
        'telemetryOptOut' => false,
        'disabledTools' => %w[tool1 tool2]
      )
    end
  end
end
