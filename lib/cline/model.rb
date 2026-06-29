module Cline
  # Cline model information
  class Model < Schema
    # @!group Public API

    # @return [String] Model display name
    attribute :name, :string

    # @return [Integer] Maximum tokens output for this model
    attribute :max_tokens, :integer

    # @return [Integer] Context window size in tokens
    attribute :context_window, :integer

    # @return [Boolean] True if this model supports image inputs
    attribute :supports_images, :boolean

    # @return [Boolean] True if this model supports prompt caching
    attribute :supports_prompt_cache, :boolean

    # @return [Float] Input price per million tokens
    attribute :input_price, :float

    # @return [Float] Output price per million tokens
    attribute :output_price, :float

    # @return [Float, nil] Cache reads price per million tokens
    attribute :cache_reads_price, :float

    # @return [Float, nil] Cache writes price per million tokens
    attribute :cache_writes_price, :float

    # @return [String, nil] Model description
    attribute :description, :string

    # Thinking configuration for this model
    class ThinkingConfig < Schema
      # @!group Public API

      # @return [Integer] Maximum thinking budget in tokens
      attribute :max_budget, :integer
    end

    # @return [ThinkingConfig, nil] Thinking configuration
    attribute :thinking_config, ThinkingConfig
  end
end
