describe Cline::Secrets, '#cast' do
  # @return [Cline::Secrets] A secrets instance to be tested
  attr_reader :secrets

  around do |example|
    with_secrets(create: true) do |secrets|
      @secrets = secrets
      example.run
    end
  end

  it 'initializes cline_api_key from String' do
    secrets.cline_api_key = 'test-api-key'
    expect(secrets.cline_api_key.to_unprotected).to eq 'test-api-key'
  end

  it 'initializes open_ai_api_key from String' do
    secrets.open_ai_api_key = 'test-openai-key'
    expect(secrets.open_ai_api_key.to_unprotected).to eq 'test-openai-key'
  end

  it 'initializes gemini_api_key from String' do
    secrets.gemini_api_key = 'test-gemini-key'
    expect(secrets.gemini_api_key.to_unprotected).to eq 'test-gemini-key'
  end

  it 'initializes api_key from String' do
    secrets.api_key = 'test-api-key'
    expect(secrets.api_key.to_unprotected).to eq 'test-api-key'
  end

  it 'initializes aws_access_key from String' do
    secrets.aws_access_key = 'test-aws-access-key'
    expect(secrets.aws_access_key.to_unprotected).to eq 'test-aws-access-key'
  end

  it 'initializes aws_secret_key from String' do
    secrets.aws_secret_key = 'test-aws-secret-key'
    expect(secrets.aws_secret_key.to_unprotected).to eq 'test-aws-secret-key'
  end

  it 'initializes aws_session_token from String' do
    secrets.aws_session_token = 'test-aws-session-token'
    expect(secrets.aws_session_token.to_unprotected).to eq 'test-aws-session-token'
  end

  it 'initializes deep_seek_api_key from String' do
    secrets.deep_seek_api_key = 'test-deepseek-key'
    expect(secrets.deep_seek_api_key.to_unprotected).to eq 'test-deepseek-key'
  end

  it 'initializes open_ai_native_api_key from String' do
    secrets.open_ai_native_api_key = 'test-openai-native-key'
    expect(secrets.open_ai_native_api_key.to_unprotected).to eq 'test-openai-native-key'
  end

  it 'initializes open_router_api_key from String' do
    secrets.open_router_api_key = 'test-openrouter-key'
    expect(secrets.open_router_api_key.to_unprotected).to eq 'test-openrouter-key'
  end

  it 'initializes lite_llm_api_key from String' do
    secrets.lite_llm_api_key = 'test-litellm-key'
    expect(secrets.lite_llm_api_key.to_unprotected).to eq 'test-litellm-key'
  end

  it 'initializes sap_ai_core_client_id from String' do
    secrets.sap_ai_core_client_id = 'test-sap-client-id'
    expect(secrets.sap_ai_core_client_id.to_unprotected).to eq 'test-sap-client-id'
  end

  it 'initializes sap_ai_core_client_secret from String' do
    secrets.sap_ai_core_client_secret = 'test-sap-client-secret'
    expect(secrets.sap_ai_core_client_secret.to_unprotected).to eq 'test-sap-client-secret'
  end

  it 'initializes mistral_api_key from String' do
    secrets.mistral_api_key = 'test-mistral-key'
    expect(secrets.mistral_api_key.to_unprotected).to eq 'test-mistral-key'
  end

  it 'initializes zai_api_key from String' do
    secrets.zai_api_key = 'test-zai-key'
    expect(secrets.zai_api_key.to_unprotected).to eq 'test-zai-key'
  end

  it 'initializes groq_api_key from String' do
    secrets.groq_api_key = 'test-groq-key'
    expect(secrets.groq_api_key.to_unprotected).to eq 'test-groq-key'
  end

  it 'initializes cerebras_api_key from String' do
    secrets.cerebras_api_key = 'test-cerebras-key'
    expect(secrets.cerebras_api_key.to_unprotected).to eq 'test-cerebras-key'
  end

  it 'initializes vercel_ai_gateway_api_key from String' do
    secrets.vercel_ai_gateway_api_key = 'test-vercel-key'
    expect(secrets.vercel_ai_gateway_api_key.to_unprotected).to eq 'test-vercel-key'
  end

  it 'initializes baseten_api_key from String' do
    secrets.baseten_api_key = 'test-baseten-key'
    expect(secrets.baseten_api_key.to_unprotected).to eq 'test-baseten-key'
  end

  it 'initializes requesty_api_key from String' do
    secrets.requesty_api_key = 'test-requesty-key'
    expect(secrets.requesty_api_key.to_unprotected).to eq 'test-requesty-key'
  end

  it 'initializes fireworks_api_key from String' do
    secrets.fireworks_api_key = 'test-fireworks-key'
    expect(secrets.fireworks_api_key.to_unprotected).to eq 'test-fireworks-key'
  end

  it 'initializes together_api_key from String' do
    secrets.together_api_key = 'test-together-key'
    expect(secrets.together_api_key.to_unprotected).to eq 'test-together-key'
  end

  it 'initializes qwen_api_key from String' do
    secrets.qwen_api_key = 'test-qwen-key'
    expect(secrets.qwen_api_key.to_unprotected).to eq 'test-qwen-key'
  end

  it 'initializes doubao_api_key from String' do
    secrets.doubao_api_key = 'test-doubao-key'
    expect(secrets.doubao_api_key.to_unprotected).to eq 'test-doubao-key'
  end

  it 'initializes moonshot_api_key from String' do
    secrets.moonshot_api_key = 'test-moonshot-key'
    expect(secrets.moonshot_api_key.to_unprotected).to eq 'test-moonshot-key'
  end

  it 'initializes hugging_face_api_key from String' do
    secrets.hugging_face_api_key = 'test-huggingface-key'
    expect(secrets.hugging_face_api_key.to_unprotected).to eq 'test-huggingface-key'
  end

  it 'initializes nebius_api_key from String' do
    secrets.nebius_api_key = 'test-nebius-key'
    expect(secrets.nebius_api_key.to_unprotected).to eq 'test-nebius-key'
  end

  it 'initializes asksage_api_key from String' do
    secrets.asksage_api_key = 'test-asksage-key'
    expect(secrets.asksage_api_key.to_unprotected).to eq 'test-asksage-key'
  end

  it 'initializes xai_api_key from String' do
    secrets.xai_api_key = 'test-xai-key'
    expect(secrets.xai_api_key.to_unprotected).to eq 'test-xai-key'
  end

  it 'initializes sambanova_api_key from String' do
    secrets.sambanova_api_key = 'test-sambanova-key'
    expect(secrets.sambanova_api_key.to_unprotected).to eq 'test-sambanova-key'
  end

  it 'initializes huawei_cloud_maas_api_key from String' do
    secrets.huawei_cloud_maas_api_key = 'test-huawei-key'
    expect(secrets.huawei_cloud_maas_api_key.to_unprotected).to eq 'test-huawei-key'
  end

  it 'initializes dify_api_key from String' do
    secrets.dify_api_key = 'test-dify-key'
    expect(secrets.dify_api_key.to_unprotected).to eq 'test-dify-key'
  end

  it 'initializes minimax_api_key from String' do
    secrets.minimax_api_key = 'test-minimax-key'
    expect(secrets.minimax_api_key.to_unprotected).to eq 'test-minimax-key'
  end

  it 'initializes hicap_api_key from String' do
    secrets.hicap_api_key = 'test-hicap-key'
    expect(secrets.hicap_api_key.to_unprotected).to eq 'test-hicap-key'
  end

  it 'initializes aihubmix_api_key from String' do
    secrets.aihubmix_api_key = 'test-aihubmix-key'
    expect(secrets.aihubmix_api_key.to_unprotected).to eq 'test-aihubmix-key'
  end

  it 'initializes nous_research_api_key from String' do
    secrets.nous_research_api_key = 'test-nous-key'
    expect(secrets.nous_research_api_key.to_unprotected).to eq 'test-nous-key'
  end

  it 'initializes wandb_api_key from String' do
    secrets.wandb_api_key = 'test-wandb-key'
    expect(secrets.wandb_api_key.to_unprotected).to eq 'test-wandb-key'
  end
end
