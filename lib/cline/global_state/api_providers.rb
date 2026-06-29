module Cline
  class GlobalState
    # API provider endpoints and authentication settings
    module ApiProviders
      # Define all the attributes of the included class
      #
      # @param base [Class] Base class including this mixin
      def self.included(base)
        base.class_eval do
          # @!group Public API

          # @return [Hash] OpenAI custom headers
          attribute :open_ai_headers, Utils::Schema.map(:string)

          # @return [Boolean] SAP AI Core orchestration mode flag
          attribute :sap_ai_core_use_orchestration_mode, :boolean

          # @return [String] Anthropic API base URL
          attribute :anthropic_base_url, :string

          # @return [String] OpenRouter provider sorting preference
          attribute :open_router_provider_sorting, :string

          # @return [String] AWS authentication method
          attribute :aws_authentication, :string

          # @return [String] Ollama API context window number
          attribute :ollama_api_options_ctx_num, :string

          # @return [String] LM Studio base URL
          attribute :lm_studio_base_url, :string

          # @return [String] LM Studio maximum tokens
          attribute :lm_studio_max_tokens, :string

          # @return [String] Gemini API base URL
          attribute :gemini_base_url, :string

          # @return [String] Azure API version
          attribute :azure_api_version, :string

          # @return [Integer] Request timeout in milliseconds
          attribute :request_timeout_ms, :integer
        end
      end
    end
  end
end
