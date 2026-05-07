require 'time'

module Cline
  # Task's message
  class Message < Schema
    # @!group Public API

    # Model info in messages
    class ModelInfo < Schema
      # @return [String] Provider
      attribute :provider_id, :string

      # @return [String] Model
      attribute :model_id, :string

      # @return [String] Mode (plan or act)
      attribute :mode, :string
    end

    # @return [Integer] Message timestamp
    attribute :ts, :integer

    # @return [String] Message type identifier
    attribute :type, :string

    # @return [String] Say message identifier
    attribute :say, :string

    # @return [String] Ask message identifier
    attribute :ask, :string

    # @return [String] Raw text content of the message
    attribute :text, :string

    # @return [ModelInfo] Model metadata
    attribute :model_info, ModelInfo

    # @return [Integer] Position index within the conversation history sequence
    attribute :conversation_history_index, :integer

    # @return [Boolean] Flag indicating this is an incomplete streaming message
    attribute :partial, :boolean

    # Get the message timestamp as a Ruby time
    #
    # @return [Time] The message timestamp
    def timestamp
      @timestamp ||= Time.at(ts / 1000.0)
    end

    # Get the usage statistics of this message, if any
    #
    # @return [Usage, nil] The usage statistics, or nil if none
    def usage
      return unless type == 'say' && say == 'api_req_started'

      api_details = JSON.parse(text, symbolize_names: true)
      Usage.new(
        **{
          cost: api_details[:cost],
          input_tokens: api_details[:tokensIn],
          output_tokens: api_details[:tokensOut],
          cache_read_tokens: api_details[:cacheReads],
          cache_write_tokens: api_details[:cacheWrites],
          cline_model: cline_models[model_info.model_id]
        }.compact
      )
    end

    # @!group Internal

    # Parse a Hash object and instantiate the proper instance from it.
    #
    # @param hash [Hash] Data
    # @param args [Array] Remaining arguments to be transferred to Shale
    # @param cline_models [Models] The Clines models used to interpret the message
    # @param kwargs [Hash] Remaining kwargs to be transferred to Shale
    # @return [Schema] Corresponding instance
    def self.of_hash(hash, *args, cline_models:, **kwargs)
      instance = super(hash, *args, **kwargs)
      instance.cline_models = cline_models
      instance
    end

    # @return [Models] The Clines models used to interpret the message
    attr_accessor :cline_models
  end
end
