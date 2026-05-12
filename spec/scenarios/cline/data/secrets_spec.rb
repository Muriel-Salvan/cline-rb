describe Cline::Data, '#secrets' do
  it 'returns nil when no secrets file exists in data directory' do
    with_data(secrets: nil) do |data|
      expect(data.secrets).to be_nil
    end
  end

  it 'initializes secrets when data is initialized with create option' do
    with_data(secrets: nil, create: true) do |data|
      expect(data.secrets).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'secrets.json'))).to be true
    end
  end

  it 'initializes secrets when create option is given' do
    with_data(secrets: nil) do |data|
      expect(data.secrets(create: true)).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'secrets.json'))).to be true
    end
  end

  it 'ignores extra unknown parameters from secrets file' do
    with_data(
      secrets: {
        cline_api_key: 'sk_abf',
        unknown_parameter: 'should be ignored',
        another_extra_field: 12_345
      }
    ) do |data|
      secrets = data.secrets
      # Verify valid attributes are still correctly loaded
      expect(secrets.cline_api_key.to_unprotected).to eq 'sk_abf'
      # Verify unknown parameters are not present on the object
      expect(secrets).not_to respond_to(:unknown_parameter)
      expect(secrets).not_to respond_to(:another_extra_field)
    end
  end

  it 'loads all secrets attributes' do
    with_data(
      secrets: {
        clineApiKey: 'sk_abcde',
        openAiApiKey: 'sk_opena',
        geminiApiKey: 'sk_gemin',
        apiKey: 'sk_apike',
        awsAccessKey: 'sk_awsac',
        awsSecretKey: 'sk_awsse',
        awsSessionToken: 'sk_awsto',
        deepSeekApiKey: 'sk_deeps',
        openAiNativeApiKey: 'sk_opnai',
        openRouterApiKey: 'sk_oprtr',
        liteLlmApiKey: 'sk_litll',
        sapAiCoreClientId: 'sk_sapcc',
        sapAiCoreClientSecret: 'sk_sapcs',
        mistralApiKey: 'sk_mistr',
        zaiApiKey: 'sk_zai8c',
        groqApiKey: 'sk_groq8',
        cerebrasApiKey: 'sk_cereb',
        vercelAiGatewayApiKey: 'sk_vrcel',
        basetenApiKey: 'sk_baset',
        requestyApiKey: 'sk_rqsty',
        fireworksApiKey: 'sk_fwork',
        togetherApiKey: 'sk_togth',
        qwenApiKey: 'sk_qwen8',
        doubaoApiKey: 'sk_douba',
        moonshotApiKey: 'sk_moons',
        huggingFaceApiKey: 'sk_huggi',
        nebiusApiKey: 'sk_nebiu',
        asksageApiKey: 'sk_askag',
        xaiApiKey: 'sk_xai8c',
        sambanovaApiKey: 'sk_samba',
        huaweiCloudMaasApiKey: 'sk_hwclm',
        difyApiKey: 'sk_dify8',
        minimaxApiKey: 'sk_minim',
        hicapApiKey: 'sk_hicap',
        aihubmixApiKey: 'sk_ahubi',
        nousResearchApiKey: 'sk_nousr',
        wandbApiKey: 'sk_wandb'
      }
    ) do |data|
      secrets = data.secrets
      expect(secrets.cline_api_key.to_unprotected).to eq 'sk_abcde'
      expect(secrets.open_ai_api_key.to_unprotected).to eq 'sk_opena'
      expect(secrets.gemini_api_key.to_unprotected).to eq 'sk_gemin'
      expect(secrets.api_key.to_unprotected).to eq 'sk_apike'
      expect(secrets.aws_access_key.to_unprotected).to eq 'sk_awsac'
      expect(secrets.aws_secret_key.to_unprotected).to eq 'sk_awsse'
      expect(secrets.aws_session_token.to_unprotected).to eq 'sk_awsto'
      expect(secrets.deep_seek_api_key.to_unprotected).to eq 'sk_deeps'
      expect(secrets.open_ai_native_api_key.to_unprotected).to eq 'sk_opnai'
      expect(secrets.open_router_api_key.to_unprotected).to eq 'sk_oprtr'
      expect(secrets.lite_llm_api_key.to_unprotected).to eq 'sk_litll'
      expect(secrets.sap_ai_core_client_id.to_unprotected).to eq 'sk_sapcc'
      expect(secrets.sap_ai_core_client_secret.to_unprotected).to eq 'sk_sapcs'
      expect(secrets.mistral_api_key.to_unprotected).to eq 'sk_mistr'
      expect(secrets.zai_api_key.to_unprotected).to eq 'sk_zai8c'
      expect(secrets.groq_api_key.to_unprotected).to eq 'sk_groq8'
      expect(secrets.cerebras_api_key.to_unprotected).to eq 'sk_cereb'
      expect(secrets.vercel_ai_gateway_api_key.to_unprotected).to eq 'sk_vrcel'
      expect(secrets.baseten_api_key.to_unprotected).to eq 'sk_baset'
      expect(secrets.requesty_api_key.to_unprotected).to eq 'sk_rqsty'
      expect(secrets.fireworks_api_key.to_unprotected).to eq 'sk_fwork'
      expect(secrets.together_api_key.to_unprotected).to eq 'sk_togth'
      expect(secrets.qwen_api_key.to_unprotected).to eq 'sk_qwen8'
      expect(secrets.doubao_api_key.to_unprotected).to eq 'sk_douba'
      expect(secrets.moonshot_api_key.to_unprotected).to eq 'sk_moons'
      expect(secrets.hugging_face_api_key.to_unprotected).to eq 'sk_huggi'
      expect(secrets.nebius_api_key.to_unprotected).to eq 'sk_nebiu'
      expect(secrets.asksage_api_key.to_unprotected).to eq 'sk_askag'
      expect(secrets.xai_api_key.to_unprotected).to eq 'sk_xai8c'
      expect(secrets.sambanova_api_key.to_unprotected).to eq 'sk_samba'
      expect(secrets.huawei_cloud_maas_api_key.to_unprotected).to eq 'sk_hwclm'
      expect(secrets.dify_api_key.to_unprotected).to eq 'sk_dify8'
      expect(secrets.minimax_api_key.to_unprotected).to eq 'sk_minim'
      expect(secrets.hicap_api_key.to_unprotected).to eq 'sk_hicap'
      expect(secrets.aihubmix_api_key.to_unprotected).to eq 'sk_ahubi'
      expect(secrets.nous_research_api_key.to_unprotected).to eq 'sk_nousr'
      expect(secrets.wandb_api_key.to_unprotected).to eq 'sk_wandb'
    end
  end

  describe '#save' do
    it 'persists modified attributes to the secrets.json file' do
      with_data(
        secrets: {
          clineApiKey: 'sk_abf',
          openAiApiKey: 'openapiapikey',
          unknownParameter: 'Unknown value'
        }
      ) do |data|
        secrets = data.secrets
        secrets.cline_api_key = Cline::SecretString.new('sk_updated')
        secrets.save
        file_content = JSON.parse(File.read(File.join(data.dir, 'secrets.json')))
        expect(file_content['clineApiKey']).to eq 'sk_updated'
        expect(file_content['openAiApiKey']).to eq 'openapiapikey'
        expect(file_content['unknownParameter']).to eq 'Unknown value'
      end
    end

    it 'persists a newly instantiated secrets file' do
      with_data(secrets: nil) do |data|
        secrets = data.secrets(create: true)
        secrets.cline_api_key = Cline::SecretString.new('sk_newkey')
        secrets.save
        expect(JSON.parse(File.read(File.join(data.dir, 'secrets.json')), symbolize_names: true)).to eq(
          {
            clineApiKey: 'sk_newkey'
          }
        )
      end
    end
  end

  describe '#==' do
    it 'returns true when 2 secrets from different data directories have the same content' do
      secrets_hash = {
        clineApiKey: 'sk_abf',
        openAiApiKey: 'openapiapikey'
      }
      with_data(secrets: secrets_hash) do |data1|
        s1 = data1.secrets
        with_data(secrets: secrets_hash) do |data2|
          s2 = data2.secrets
          # Secrets are from different data directories but have identical content
          expect(s1).not_to equal(s2) # Different instances
          expect(s1).to eq(s2)
        end
      end
    end

    it 'returns false when 2 secrets have different attributes' do
      with_data(secrets: { clineApiKey: 'sk_abf' }) do |data1|
        with_data(secrets: { clineApiKey: 'sk_xyz' }) do |data2|
          expect(data1.secrets).not_to eq(data2.secrets)
        end
      end
    end

    it 'returns false when 2 secrets have unknown attributes with different values' do
      with_data(secrets: { clineApiKey: 'sk_abf', unknown_field: 1 }) do |data1|
        with_data(secrets: { clineApiKey: 'sk_abf', unknown_field: 2 }) do |data2|
          expect(data1.secrets).not_to eq(data2.secrets)
        end
      end
    end
  end
end
