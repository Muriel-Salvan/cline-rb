module Cline
  # Task's message
  class Message < Schema
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
  end
end
