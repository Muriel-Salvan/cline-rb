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
      # Its values are filled by the LLM, whose types are not guaranteed by the Cline CLI:
      # deserialization is therefore lenient (wrong values do not raise but are stored in {#wrong_attributes}).
      class ToolUseInput < LenientSchema
        # @!group Public API

        # A file to be read by the read_files tool
        # The path is expected to be a String: a wrong type (e.g. an Array) is reported as a deserialization error.
        class FileInput < Schema
          # @!group Public API

          strict_types!

          # @return [String] File path
          attribute :path, :string
        end

        # @return [String] Question
        attribute :question, :string

        # @return [String, Array<String>, nil] List of options for the given question
        attribute :options, Utils::Schema.union(:string, Utils::Schema.collection(:string))

        # @return [String, nil] File path (for editor / read_files tools)
        attribute :path, :string

        # @return [String, nil] New file content (for editor tool)
        attribute :new_text, :string

        # @return [String, nil] Old file content (for editor tool)
        attribute :old_text, :string

        # @return [String, Array<String>, nil] Shell commands to run (for run_commands tool)
        attribute :commands, Utils::Schema.union(:string, Utils::Schema.collection(:string))

        # @return [Array<FileInput>, nil] Files to read (for read_files tool)
        attribute :files, Utils::Schema.collection(FileInput)

        cline_snake_attributes :new_text, :old_text
      end

      # A content entry of a tool result that is not a plain String.
      class ToolResultContent < Schema
        # @!group Public API

        # @return [String, nil] Query or command executed by the tool
        attribute :query, :string

        # @return [String, nil] Result of the query or command
        attribute :result, :string

        # @return [Boolean, nil] Whether the query or command succeeded
        attribute :success, :boolean

        # Get a human-readable representation of this tool result.
        #
        # @return [String] The result of the tool, or its query if there is no result
        def to_s
          result || query || ''
        end
      end

      # @return [String] Content block type (text, tool_use, tool_result)
      attribute :type, :string

      # @return [String, nil] Text content (for type "text")
      attribute :text, :string

      # @return [String, nil] Thinking content (for type "thinking")
      attribute :thinking, :string

      # @return [String, nil] Tool use identifier (for type "tool_use")
      attribute :id, :string

      # @return [String, nil] Tool name (for type "tool_use")
      attribute :name, :string

      # @return [ToolUseInput, nil] Tool input parameters (for type "tool_use")
      attribute :input, ToolUseInput

      # @return [String, nil] Tool use identifier this result corresponds to (for type "tool_result")
      attribute :tool_use_id, :string

      # @return [String, Array<ToolResultContent>, nil] Content of the tool result (for type "tool_result")
      attribute :content, Utils::Schema.union(:string, Utils::Schema.collection(ToolResultContent))

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
          "Tool result: #{human_tool_result}"
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

    # Get a human representation of the tool result content of this message.
    #
    # @return [String] The tool result content, as a String
    def human_tool_result
      tool_result = content.find { |c| c.type == 'tool_result' }&.content
      return tool_result.to_s if tool_result.nil? || tool_result.is_a?(String)

      Array(tool_result).join(' ')
    end
  end
end
