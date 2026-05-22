describe Cline::Secrets, '#==' do
  it 'returns true when 2 secrets from different data directories have the same content' do
    secrets_hash = {
      clineApiKey: 'sk_abf',
      openAiApiKey: 'openapiapikey'
    }
    with_secrets(secrets: secrets_hash) do |s1|
      with_secrets(secrets: secrets_hash) do |s2|
        # Secrets are from different data directories but have identical content
        expect(s1).not_to equal(s2) # Different instances
        expect(s1).to eq(s2)
      end
    end
  end

  it 'returns false when 2 secrets have different attributes' do
    with_secrets(secrets: { clineApiKey: 'sk_abf' }) do |s1|
      with_secrets(secrets: { clineApiKey: 'sk_xyz' }) do |s2|
        expect(s1).not_to eq(s2)
      end
    end
  end

  it 'returns false when 2 secrets have unknown attributes with different values' do
    with_secrets(secrets: { clineApiKey: 'sk_abf', unknownField: 1 }) do |s1|
      with_secrets(secrets: { clineApiKey: 'sk_abf', unknownField: 2 }) do |s2|
        expect(s1).not_to eq(s2)
      end
    end
  end
end
