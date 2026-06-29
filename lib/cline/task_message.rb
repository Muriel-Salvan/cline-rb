require 'ellipsized'
require 'time'

module Cline
  # Task's message
  class TaskMessage < Schema
    # @!group Public API

    # Model info in messages
    class ModelInfo < Schema
      # @!group Public API

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

    # Return a human-friendly version of a message.
    # Useful for stdout or logging.
    #
    # @param limit [Integer] Number of characters the message should be limited to
    # @return [String] The human translation
    def to_human(limit: 128)
      case type
      when 'say'
        case say
        when 'text', 'task'
          one_lining(text)
        when 'api_req_started'
          sections = parse_sections(JSON.parse(text, symbolize_names: true)[:request])
          section_delimiter = '|'
          # Ignore some sections
          sections.reject! { |section| section[:name] == 'environment_details' }
          section_size = (limit / sections.size) - section_delimiter.size
          sections.map do |section|
            "#{"#{section[:name]}: " if section[:name]}#{one_lining(section[:content])}".ellipsized(section_size)
          end.join('|')
        when 'tool'
          tool_details = JSON.parse(text, symbolize_names: true)
          tool_header =
            case tool_details[:tool]
            when 'readFile'
              "[readFile] - #{tool_details[:path]}"
            when 'listFilesRecursive'
              "[listFilesRecursive] - #{tool_details[:path]}"
            when 'listFilesTopLevel'
              "[listFilesTopLevel] - #{tool_details[:path]}"
            when 'newFileCreated'
              "[newFileCreated] - #{tool_details[:path]}"
            when 'editedExistingFile'
              "[editedExistingFile] - #{tool_details[:path]}"
            when 'searchFiles'
              "[searchFiles] - #{tool_details[:path]} (regex: #{tool_details[:regex]})"
            when 'useSkill'
              "[useSkill] - #{tool_details[:skill_name]}"
            else
              raise NotImplementedError, "Unknown tool @ts #{ts}: #{self}"
            end
          "#{tool_header}#{": #{one_lining(tool_details[:content])}".ellipsized(limit - tool_header.size) if tool_details.key?(:content)}"
        when 'api_req_retried'
          'API request retried'
        when 'command'
          "Command: #{one_lining(text)}"
        when 'command_output'
          "Command output: #{one_lining(text)}"
        when 'diff_error'
          "Diff error: #{one_lining(text)}"
        when 'error_retry'
          "Error retry: #{one_lining(text)}"
        when 'reasoning'
          "Reasoning: #{one_lining(text)}"
        when 'user_feedback'
          "User feedback: #{one_lining(text)}"
        when 'task_progress'
          # Count completed vs total tasks
          completed_tasks = text.scan('- [x]').size
          total_tasks = text.scan(/- \[[ x]\]/).size
          "Task progress: #{completed_tasks}/#{total_tasks} tasks"
        when 'completion_result'
          "Task completed: #{one_lining(text)}"
        when 'error'
          "Error: #{one_lining(text)}"
        else
          raise NotImplementedError, "Unknown say @ts #{ts}: #{self}"
        end
      when 'ask'
        "Ask user: #{
          case ask
          when 'resume_task'
            'Resume task'
          when 'resume_completed_task'
            'Resume completed task'
          when 'api_req_failed'
            details = JSON.parse(text, symbolize_names: true)
            "API request failed - #{details[:code]} - #{one_lining(details[:message])}"
          when 'command_output'
            "Command output - #{one_lining(text)}"
          when 'completion_result'
            'Completion result'
          when 'followup'
            details = JSON.parse(text, symbolize_names: true)
            "Follow-up - #{details[:question]}#{" - Options: #{details[:options].join(', ')}" unless details[:options].nil? || details[:options].empty?}"
          when 'plan_mode_respond'
            details = JSON.parse(text, symbolize_names: true)
            "Plan mode respond - #{one_lining(details[:response])}}"
          when 'tool'
            details = JSON.parse(text, symbolize_names: true)
            tool_name = details.delete(:tool)
            "Use tool - #{tool_name} - #{details.to_json}}"
          when 'mistake_limit_reached'
            "Mistake limit reached - #{one_lining(text)}}"
          when 'new_task'
            "New task - #{one_lining(text)}"
          else
            raise NotImplementedError, "Unknown ask @ts #{ts}: #{self}"
          end
        }"
      else
        raise NotImplementedError, "Unknown type @ts #{ts}: #{self}"
      end.ellipsized(limit)
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

    private

    # Convert a string to a single line by replacing newlines with spaces and removing carriage returns
    #
    # @param text [String] The text to convert to one line
    # @return [String] The text converted to a single line
    def one_lining(text)
      text.strip.gsub("\n", ' ').gsub("\r", '')
    end

    # Use a single regex to match complete tag pairs
    # This regex matches <tag>content</tag> patterns
    COMPLETE_TAG_PATTERN = %r{<([a-zA-Z0-9_:]*)>(.*?)</\1>}m
    private_constant :COMPLETE_TAG_PATTERN

    # Parse sections from a string with HTML-like tags.
    # Sections are delimited by html-like tags, for example `<toto>...</toto>` is the section named `toto`.
    # Sections without tags should still be part of the result, with a nil section name.
    # Only considers top-level tags (no recursion).
    #
    # @param content [String] The input string to parse
    # @return [Array<Hash{Symbol => Object}>] List of sections found from the content. Each section can have the following properties:
    #   * name [String, nil] Section name, or nil if no name was given to this section (in-between named sections).
    #   * content [String] Section content.
    def parse_sections(content)
      sections = []
      current_pos = 0
      content_length = content.length
      # Use cursor progression to maintain order
      while current_pos < content_length
        # Find the next complete tag pair starting from current position
        match = content.match(COMPLETE_TAG_PATTERN, current_pos)
        if match
          # Add any untagged content before this tag
          if match.begin(0) > current_pos
            untagged_content = content[current_pos...match.begin(0)]
            sections << { name: nil, content: untagged_content } unless untagged_content.strip.empty?
          end
          # Add the tagged section
          sections << { name: match[1], content: match[2] }
          current_pos = match.end(0)
        else
          # No more tags found, add remaining content
          remaining_content = content[current_pos..]
          sections << { name: nil, content: remaining_content } unless remaining_content.strip.empty?
          current_pos = content_length
        end
      end
      sections
    end
  end
end
