module Cline
  class GlobalSettings
    # Model and AI configuration settings
    module Models
      # Thinking configuration for models
      class ThinkingConfig < Schema
        # @return [Integer] Maximum thinking budget tokens
        attribute :max_budget, :integer
      end

      # OpenRouter model information
      class OpenRouterModelInfo < Schema
        # @return [String] Model name
        attribute :name, :string

        # @return [Integer] Maximum tokens allowed per request
        attribute :max_tokens, :integer

        # @return [Integer] Context window size
        attribute :context_window, :integer

        # @return [Boolean] Flag indicating image support
        attribute :supports_images, :boolean

        # @return [Boolean] Flag indicating prompt cache support
        attribute :supports_prompt_cache, :boolean

        # @return [Float] Input token price
        attribute :input_price, :float

        # @return [Float] Output token price
        attribute :output_price, :float

        # @return [Float] Cache reads price
        attribute :cache_reads_price, :float

        # @return [String] Model description
        attribute :description, :string

        # @return [ThinkingConfig] Thinking configuration
        attribute :thinking_config, ThinkingConfig
      end

      # Define all the attributes of the included class
      #
      # @param base [Class] Base class including this mixin
      def self.included(base)
        base.class_eval do
          # @return [OpenRouterModelInfo] OpenRouter model information for Act mode
          attribute :act_mode_open_router_model_info, OpenRouterModelInfo

          # @return [OpenRouterModelInfo] OpenRouter model information for Plan mode
          attribute :plan_mode_open_router_model_info, OpenRouterModelInfo

          # @return [OpenRouterModelInfo] Cline model information for Act mode
          attribute :act_mode_cline_model_info, OpenRouterModelInfo

          # @return [OpenRouterModelInfo] Cline model information for Plan mode
          attribute :plan_mode_cline_model_info, OpenRouterModelInfo

          # @return [String] API provider used for Act mode
          attribute :act_mode_api_provider, :string

          # @return [String] API provider used for Plan mode
          attribute :plan_mode_api_provider, :string

          # @return [String] Cline model identifier for Act mode
          attribute :act_mode_cline_model_id, :string

          # @return [String] Cline model identifier for Plan mode
          attribute :plan_mode_cline_model_id, :string

          # @return [String] Reasoning effort level for Act mode
          attribute :act_mode_reasoning_effort, :string

          # @return [String] Reasoning effort level for Plan mode
          attribute :plan_mode_reasoning_effort, :string

          # @return [Integer] Thinking budget token limit for Plan mode
          attribute :plan_mode_thinking_budget_tokens, :integer

          # @return [Integer] Thinking budget token limit for Act mode
          attribute :act_mode_thinking_budget_tokens, :integer

          # @return [String] OpenRouter model identifier for Act mode
          attribute :act_mode_open_router_model_id, :string

          # @return [String] OpenRouter model identifier for Plan mode
          attribute :plan_mode_open_router_model_id, :string

          # @return [String] API model identifier for Plan mode
          attribute :plan_mode_api_model_id, :string

          # @return [String] API model identifier for Act mode
          attribute :act_mode_api_model_id, :string

          # @return [String] Ollama model identifier for Plan mode
          attribute :plan_mode_ollama_model_id, :string

          # @return [String] LM Studio model identifier for Plan mode
          attribute :plan_mode_lm_studio_model_id, :string

          # @return [String] Fireworks model identifier for Plan mode
          attribute :plan_mode_fireworks_model_id, :string

          # @return [String] Ollama model identifier for Act mode
          attribute :act_mode_ollama_model_id, :string

          # @return [String] LM Studio model identifier for Act mode
          attribute :act_mode_lm_studio_model_id, :string

          # @return [String] Fireworks model identifier for Act mode
          attribute :act_mode_fireworks_model_id, :string

          # @return [Boolean] Plan/Act separate models setting
          attribute :plan_act_separate_models_setting, :boolean
        end
      end
    end
  end
end
