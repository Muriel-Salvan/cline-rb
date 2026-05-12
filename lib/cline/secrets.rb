module Cline
  # Access secrets stored in the data directory's secrets.json file
  class Secrets < Schema
    Serializable::ClineData.include_for(self, 'secrets.json')

    # @return [SecretString, nil] Cline API key
    attribute :cline_api_key, SecretString

    # @return [SecretString, nil] OpenAI API key
    attribute :open_ai_api_key, SecretString

    # @return [SecretString, nil] Gemini API key
    attribute :gemini_api_key, SecretString

    # @return [SecretString, nil] Generic API key
    attribute :api_key, SecretString

    # @return [SecretString, nil] AWS access key
    attribute :aws_access_key, SecretString

    # @return [SecretString, nil] AWS secret key
    attribute :aws_secret_key, SecretString

    # @return [SecretString, nil] AWS session token
    attribute :aws_session_token, SecretString

    # @return [SecretString, nil] DeepSeek API key
    attribute :deep_seek_api_key, SecretString

    # @return [SecretString, nil] OpenAI native API key
    attribute :open_ai_native_api_key, SecretString

    # @return [SecretString, nil] OpenRouter API key
    attribute :open_router_api_key, SecretString

    # @return [SecretString, nil] LiteLLM API key
    attribute :lite_llm_api_key, SecretString

    # @return [SecretString, nil] SAP AI Core client ID
    attribute :sap_ai_core_client_id, SecretString

    # @return [SecretString, nil] SAP AI Core client secret
    attribute :sap_ai_core_client_secret, SecretString

    # @return [SecretString, nil] Mistral API key
    attribute :mistral_api_key, SecretString

    # @return [SecretString, nil] ZAI API key
    attribute :zai_api_key, SecretString

    # @return [SecretString, nil] Groq API key
    attribute :groq_api_key, SecretString

    # @return [SecretString, nil] Cerebras API key
    attribute :cerebras_api_key, SecretString

    # @return [SecretString, nil] Vercel AI Gateway API key
    attribute :vercel_ai_gateway_api_key, SecretString

    # @return [SecretString, nil] Baseten API key
    attribute :baseten_api_key, SecretString

    # @return [SecretString, nil] Requesty API key
    attribute :requesty_api_key, SecretString

    # @return [SecretString, nil] Fireworks API key
    attribute :fireworks_api_key, SecretString

    # @return [SecretString, nil] Together API key
    attribute :together_api_key, SecretString

    # @return [SecretString, nil] Qwen API key
    attribute :qwen_api_key, SecretString

    # @return [SecretString, nil] Doubao API key
    attribute :doubao_api_key, SecretString

    # @return [SecretString, nil] Moonshot API key
    attribute :moonshot_api_key, SecretString

    # @return [SecretString, nil] HuggingFace API key
    attribute :hugging_face_api_key, SecretString

    # @return [SecretString, nil] Nebius API key
    attribute :nebius_api_key, SecretString

    # @return [SecretString, nil] AskSage API key
    attribute :asksage_api_key, SecretString

    # @return [SecretString, nil] xAI API key
    attribute :xai_api_key, SecretString

    # @return [SecretString, nil] Sambanova API key
    attribute :sambanova_api_key, SecretString

    # @return [SecretString, nil] Huawei Cloud Maas API key
    attribute :huawei_cloud_maas_api_key, SecretString

    # @return [SecretString, nil] Dify API key
    attribute :dify_api_key, SecretString

    # @return [SecretString, nil] Minimax API key
    attribute :minimax_api_key, SecretString

    # @return [SecretString, nil] Hicap API key
    attribute :hicap_api_key, SecretString

    # @return [SecretString, nil] AIHubMix API key
    attribute :aihubmix_api_key, SecretString

    # @return [SecretString, nil] Nous Research API key
    attribute :nous_research_api_key, SecretString

    # @return [SecretString, nil] Weights & Biases API key
    attribute :wandb_api_key, SecretString
  end
end
