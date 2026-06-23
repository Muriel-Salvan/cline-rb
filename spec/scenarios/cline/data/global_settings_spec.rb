describe Cline::Data, '#global_settings' do
  it 'returns nil when no global settings file exists in data directory' do
    with_data(global_settings: nil) do |data|
      expect(data.global_settings).to be_nil
    end
  end

  it 'initializes global_settings when data is initialized with create option' do
    with_data(global_settings: nil, create: true) do |data|
      expect(data.global_settings).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'settings/global-settings.json'))).to be true
    end
  end

  it 'initializes global_settings when create option is given' do
    with_data(global_settings: nil) do |data|
      expect(data.global_settings(create: true)).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'settings/global-settings.json'))).to be true
    end
  end

  it 'ignores extra unknown parameters from global settings file' do
    with_data(
      global_settings: {
        autoUpdateEnabled: true,
        telemetryOptOut: false,
        disabledTools: %w[tool1 tool2],
        thisIsAnUnknownParameter: 'should be ignored',
        anotherExtraField: 12_345
      }
    ) do |data|
      global_settings = data.global_settings
      # Verify valid attributes are still correctly loaded
      expect(global_settings.auto_update_enabled).to be true
      expect(global_settings.telemetry_opt_out).to be false
      expect(global_settings.disabled_tools.to_a).to eq %w[tool1 tool2]
      # Verify unknown parameters are not present on the object
      expect(global_settings).not_to respond_to(:this_is_an_unknown_parameter)
      expect(global_settings).not_to respond_to(:thisIsAnUnknownParameter)
      expect(global_settings).not_to respond_to(:another_extra_field)
      expect(global_settings).not_to respond_to(:anotherExtraField)
    end
  end

  it 'loads all global settings attributes' do
    with_data(
      global_settings: {
        autoUpdateEnabled: true,
        telemetryOptOut: true,
        disabledTools: %w[admin-tool dangerous-tool]
      }
    ) do |data|
      global_settings = data.global_settings
      expect(global_settings.auto_update_enabled).to be true
      expect(global_settings.telemetry_opt_out).to be true
      expect(global_settings.disabled_tools.to_a).to eq %w[admin-tool dangerous-tool]
    end
  end
end
