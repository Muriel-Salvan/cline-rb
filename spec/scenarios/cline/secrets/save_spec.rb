describe Cline::Secrets, '#save' do
  it 'persists modified attributes to the secrets.json file' do
    with_secrets(
      secrets: {
        clineApiKey: 'sk_abf',
        openAiApiKey: 'openapiapikey'
      }
    ) do |secrets|
      secrets.cline_api_key = Cline::SecretString.new('sk_updated')
      secrets.save
      expect(JSON.parse(File.read(File.join(secrets.dir, 'secrets.json')))).to eq(
        'clineApiKey' => 'sk_updated',
        'openAiApiKey' => 'openapiapikey'
      )
    end
  end

  it 'persists unknown attributes to the secrets.json file' do
    with_secrets(
      secrets: {
        clineApiKey: 'sk_abf',
        openAiApiKey: 'openapiapikey',
        unknownParameter: 'Unknown value'
      }
    ) do |secrets|
      secrets.cline_api_key = Cline::SecretString.new('sk_updated')
      secrets.save
      expect(JSON.parse(File.read(File.join(secrets.dir, 'secrets.json')))).to eq(
        'clineApiKey' => 'sk_updated',
        'openAiApiKey' => 'openapiapikey',
        'unknownParameter' => 'Unknown value'
      )
    end
  end

  it 'persists a newly instantiated secrets file' do
    with_secrets(secrets: nil, create: true) do |secrets|
      secrets.cline_api_key = Cline::SecretString.new('sk_newkey')
      secrets.save
      expect(JSON.parse(File.read(File.join(secrets.dir, 'secrets.json')))).to eq(
        'clineApiKey' => 'sk_newkey'
      )
    end
  end
end
