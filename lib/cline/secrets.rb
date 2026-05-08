module Cline
  # Access secrets stored in the data directory's secrets.json file
  class Secrets < Schema
    Utils::SerializableToJson.include_for(self, 'secrets.json')

    # @return [String, nil] Cline API key
    attribute :cline_api_key, :string

    # @return [String, nil] OpenAI API key
    attribute :open_ai_api_key, :string

    # @return [String, nil] Gemini API key
    attribute :gemini_api_key, :string

    # @return [String, nil] Generic API key
    attribute :api_key, :string

    # @return [String, nil] AWS access key
    attribute :aws_access_key, :string

    # @return [String, nil] AWS secret key
    attribute :aws_secret_key, :string

    # @return [String, nil] AWS session token
    attribute :aws_session_token, :string

    # @return [String, nil] DeepSeek API key
    attribute :deep_seek_api_key, :string

    # @return [String, nil] OpenAI native API key
    attribute :open_ai_native_api_key, :string

    # @return [String, nil] OpenRouter API key
    attribute :open_router_api_key, :string

    # @return [String, nil] LiteLLM API key
    attribute :lite_llm_api_key, :string

    # @return [String, nil] SAP AI Core client ID
    attribute :sap_ai_core_client_id, :string

    # @return [String, nil] SAP AI Core client secret
    attribute :sap_ai_core_client_secret, :string

    # @return [String, nil] Mistral API key
    attribute :mistral_api_key, :string

    # @return [String, nil] ZAI API key
    attribute :zai_api_key, :string

    # @return [String, nil] Groq API key
    attribute :groq_api_key, :string

    # @return [String, nil] Cerebras API key
    attribute :cerebras_api_key, :string

    # @return [String, nil] Vercel AI Gateway API key
    attribute :vercel_ai_gateway_api_key, :string

    # @return [String, nil] Baseten API key
    attribute :baseten_api_key, :string

    # @return [String, nil] Requesty API key
    attribute :requesty_api_key, :string

    # @return [String, nil] Fireworks API key
    attribute :fireworks_api_key, :string

    # @return [String, nil] Together API key
    attribute :together_api_key, :string

    # @return [String, nil] Qwen API key
    attribute :qwen_api_key, :string

    # @return [String, nil] Doubao API key
    attribute :doubao_api_key, :string

    # @return [String, nil] Moonshot API key
    attribute :moonshot_api_key, :string

    # @return [String, nil] HuggingFace API key
    attribute :hugging_face_api_key, :string

    # @return [String, nil] Nebius API key
    attribute :nebius_api_key, :string

    # @return [String, nil] AskSage API key
    attribute :asksage_api_key, :string

    # @return [String, nil] xAI API key
    attribute :xai_api_key, :string

    # @return [String, nil] Sambanova API key
    attribute :sambanova_api_key, :string

    # @return [String, nil] Huawei Cloud Maas API key
    attribute :huawei_cloud_maas_api_key, :string

    # @return [String, nil] Dify API key
    attribute :dify_api_key, :string

    # @return [String, nil] Minimax API key
    attribute :minimax_api_key, :string

    # @return [String, nil] Hicap API key
    attribute :hicap_api_key, :string

    # @return [String, nil] AIHubMix API key
    attribute :aihubmix_api_key, :string

    # @return [String, nil] Nous Research API key
    attribute :nous_research_api_key, :string

    # @return [String, nil] Weights & Biases API key
    attribute :wandb_api_key, :string
  end
end
