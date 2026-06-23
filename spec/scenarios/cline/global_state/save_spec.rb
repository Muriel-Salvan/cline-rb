describe Cline::GlobalState, '#save' do
  it 'persists modified attributes to the globalState.json file' do
    with_global_state(
      attributes: {
        clineWebToolsEnabled: true,
        focusChainSettings: { enabled: true, remindClineInterval: 5 }
      }
    ) do |settings|
      settings.cline_web_tools_enabled = false
      settings.save
      expect(JSON.parse(File.read(File.join(settings.dir, 'globalState.json')), symbolize_names: true)).to eq(
        {
          clineWebToolsEnabled: false,
          focusChainSettings: { enabled: true, remindClineInterval: 5 }
        }
      )
    end
  end

  it 'persists unknown attributes to the globalState.json file' do
    with_global_state(
      attributes: {
        clineWebToolsEnabled: true,
        focusChainSettings: {
          enabled: true,
          remindClineInterval: 5,
          unknownParameter: 42
        },
        unknownParameter: 'Unknown value'
      }
    ) do |settings|
      settings.cline_web_tools_enabled = false
      settings.focus_chain_settings.remind_cline_interval = 1107
      settings.save
      expect(JSON.parse(File.read(File.join(settings.dir, 'globalState.json')), symbolize_names: true)).to eq(
        {
          clineWebToolsEnabled: false,
          focusChainSettings: {
            enabled: true,
            remindClineInterval: 1107,
            unknownParameter: 42
          },
          unknownParameter: 'Unknown value'
        }
      )
    end
  end

  it 'persists a newly instantiated global state file' do
    with_global_state(attributes: nil, create: true) do |settings|
      settings.cline_web_tools_enabled = true
      settings.save
      expect(JSON.parse(File.read(File.join(settings.dir, 'globalState.json')), symbolize_names: true)).to eq(
        {
          clineWebToolsEnabled: true
        }
      )
    end
  end
end
