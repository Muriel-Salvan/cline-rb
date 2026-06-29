require 'ellipsized'
require 'time'

module Cline
  # Session's message
  class SessionMessage < Schema
    # @!group Public API

    # Model info in session messages
    class ModelInfo < Schema
      # @!group Public API

      # @return [String] Model ID
      attribute :id, :string

      # @return [String] Provider
      attribute :provider, :string

      # @return [String] Model family
      attribute :family, :string
    end

    # Metrics in session messages
    class Metrics < Schema
      # @!group Public API

      # @return [Integer] Input tokens count
      attribute :input_tokens, :integer

      # @return [Integer] Output tokens count
      attribute :output_tokens, :integer

      # @return [Integer] Cache read tokens count
      attribute :cache_read_tokens, :integer

      # @return [Integer] Cache write tokens count
      attribute :cache_write_tokens, :integer

      # @return [Float] Cost of the API call
      attribute :cost, :float
    end

    # A content block in a session message.
    # All attributes are optional, some will be nil depending on the type of content.
    class MessageContent < Schema
      # @!group Public API

      # An input used for tool use content.
      class ToolUseInput < Schema
        # @!group Public API

        # @return [String] Question
        attribute :question, :string

        # @return [Array<String>] List of options for the given question
        attribute :options, Utils::Schema.collection(:string)
      end

      # @return [String] Content block type (text, tool_use, tool_result)
      attribute :type, :string

      # @return [String, nil] Text content (for type "text")
      attribute :text, :string

      # @return [String, nil] Tool use identifier (for type "tool_use")
      attribute :id, :string

      # @return [String, nil] Tool name (for type "tool_use")
      attribute :name, :string

      # @return [ToolUseInput, nil] Tool input parameters (for type "tool_use")
      attribute :input, ToolUseInput

      # @return [String, nil] Tool use identifier this result corresponds to (for type "tool_result")
      attribute :tool_use_id, :string

      # @return [String, nil] Content of the tool result (for type "tool_result")
      attribute :content, :string

      cline_snake_attributes :tool_use_id
    end

    # @return [String] Message identifier
    attribute :id, :string

    # @return [String] Role (user or assistant)
    attribute :role, :string

    # @return [Array<MessageContent>] Content blocks
    attribute :content, Utils::Schema.collection(MessageContent)

    # @return [Integer] Message timestamp in milliseconds
    attribute :ts, :integer

    # @return [ModelInfo, nil] Model metadata
    attribute :model_info, ModelInfo

    # @return [Metrics, nil] Usage metrics
    attribute :metrics, Metrics

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
      return unless metrics

      @usage ||= Usage.new(
        **{
          cost: metrics.cost,
          input_tokens: metrics.input_tokens,
          output_tokens: metrics.output_tokens,
          cache_read_tokens: metrics.cache_read_tokens,
          cache_write_tokens: metrics.cache_write_tokens,
          cline_model: cline_models && cline_models[model_info.id]
        }.compact
      )
    end

    # Return a human-friendly version of a message.
    # Useful for stdout or logging.
    #
    # @param limit [Integer] Number of characters the message should be limited to
    # @return [String] The human translation
    def to_human(limit: 128)
      (
        case role
        when 'user'
          "User: #{first_text}"
        when 'assistant'
          tool_use = content.find { |c| c.type == 'tool_use' }
          if tool_use
            "Assistant uses #{tool_use.name}"
          else
            "Assistant: #{first_text}"
          end
        when 'tool'
          "Tool result: #{content.find { |c| c.type == 'tool_result' }&.content}"
        else
          to_s
        end
      ).ellipsized(limit)
    end

    # @!group Internal

    # Parse a Hash object and instantiate the proper instance from it.
    #
    # @param hash [Hash] Data
    # @param args [Array] Remaining arguments to be transferred to Shale
    # @param cline_models [Models, nil] The Clines models used to interpret the message, or nil if none
    # @param kwargs [Hash] Remaining kwargs to be transferred to Shale
    # @return [Schema] Corresponding instance
    def self.of_hash(hash, *args, cline_models: nil, **kwargs)
      instance = super(hash, *args, **kwargs)
      instance.cline_models = cline_models if cline_models
      instance
    end

    # @return [Models] The Clines models used to interpret the message
    attr_accessor :cline_models

    private

    # Get the text from the first text content block.
    #
    # @return [String] The first text content, or an empty string if none
    def first_text
      content.find { |c| c.type == 'text' }&.text.to_s.gsub("\n", ' ')
    end
  end
end
