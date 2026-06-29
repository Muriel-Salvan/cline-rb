module Cline
  # Cline Log entry
  class Log < Schema
    # @!group Public API

    # Cause of an API call error
    class ErrorCause < Schema
      # @!group Public API

      # @return [String, nil] Error code (e.g. "ConnectionRefused")
      attribute :code, :string

      # @return [String, nil] URL path that caused the error
      attribute :path, :string

      # @return [Integer, nil] Error number
      attribute :errno, :integer
    end

    # Individual API call error (used in errors[], aggregateErrors[], and lastError)
    class ApiError < Schema
      # @!group Public API

      # @return [String, nil] Error type identifier
      attribute :type, :string

      # @return [String, nil] Human-readable error message
      attribute :message, :string

      # @return [String, nil] Error stack trace
      attribute :stack, :string

      # @return [String, nil] Error class name (e.g. "AI_APICallError")
      attribute :name, :string

      # @return [String, nil] API endpoint URL
      attribute :url, :string

      # @return [Boolean, nil] Whether the request is retryable
      attribute :is_retryable, :boolean

      # @return [ErrorCause, nil] Underlying cause of the error
      attribute :cause, ErrorCause
    end

    # Top-level error wrapper (the err field in error logs)
    class Error < Schema
      # @!group Public API

      # @return [String, nil] Error type identifier
      attribute :type, :string

      # @return [String, nil] Human-readable error message
      attribute :message, :string

      # @return [String, nil] Error stack trace
      attribute :stack, :string

      # @return [String, nil] Error class name (e.g. "AI_RetryError")
      attribute :name, :string

      # @return [String, nil] Reason for the error (e.g. "maxRetriesExceeded")
      attribute :reason, :string

      # @return [Array<ApiError>, nil] Individual errors in a retry chain
      attribute :errors, Utils::Schema.collection(ApiError)

      # @return [Array<ApiError>, nil] Aggregate errors from retry attempts
      attribute :aggregate_errors, Utils::Schema.collection(ApiError)

      # @return [ApiError, nil] Last error in a retry chain
      attribute :last_error, ApiError
    end

    # Event-specific properties for telemetry entries
    class Properties < Schema
      # @!group Public API

      # @return [String, nil] Unique identifier for tasks and sessions
      attribute :ulid, :string

      # @return [String, nil] API provider name (e.g. "cline")
      attribute :api_provider, :string

      # @return [String, nil] Agent identifier
      attribute :agent_id, :string

      # @return [String, nil] Agent kind (e.g. "team_lead")
      attribute :agent_kind, :string

      # @return [String, nil] Conversation identifier
      attribute :conversation_id, :string

      # @return [Boolean, nil] Whether this is a subagent
      attribute :is_subagent, :boolean

      # @return [String, nil] Team identifier
      attribute :team_id, :string

      # @return [String, nil] Team name
      attribute :team_name, :string

      # @return [String, nil] Team role (e.g. "lead")
      attribute :team_role, :string

      # @return [String, nil] Lead agent identifier for teams
      attribute :lead_agent_id, :string

      # @return [String, nil] Model provider (e.g. "cline")
      attribute :provider, :string

      # @return [String, nil] Model identifier (e.g. "deepseek/deepseek-v4-flash")
      attribute :model_id, :string

      # @return [String, nil] Model name (e.g. "deepseek/deepseek-v4-flash")
      attribute :model, :string

      # @return [String, nil] Source of the conversation turn (e.g. "user", "assistant")
      attribute :source, :string

      # @return [String, nil] Mode of operation (e.g. "act")
      attribute :mode, :string

      # @return [String, nil] Timestamp in ISO 8601 format
      attribute :timestamp, :string

      # @return [String, nil] Run identifier for agent runs
      attribute :run_id, :string

      # @return [String, nil] Status of a run or task (e.g. "running", "completed")
      attribute :status, :string

      # @return [Integer, nil] Iteration number
      attribute :iteration, :integer

      # @return [String, nil] Event type (e.g. "run-started", "turn-started")
      attribute :event_type, :string

      # @return [String, nil] Session identifier
      attribute :session_id, :string

      # @return [Boolean, nil] Whether tools are enabled
      attribute :enable_tools, :boolean

      # @return [Boolean, nil] Whether spawn agent is enabled
      attribute :enable_spawn_agent, :boolean

      # @return [Boolean, nil] Whether agent teams are enabled
      attribute :enable_agent_teams, :boolean

      # @return [Integer, nil] Input tokens count
      attribute :tokens_in, :integer

      # @return [Integer, nil] Output tokens count
      attribute :tokens_out, :integer

      # @return [Float, nil] Total cost of the API call
      attribute :total_cost, :float

      # @return [Integer, nil] Cache read tokens count
      attribute :cache_read_tokens, :integer

      # @return [Integer, nil] Cache write tokens count
      attribute :cache_write_tokens, :integer

      # @return [String, nil] Tool name used (e.g. "ask_question", "run_commands")
      attribute :tool, :string

      # @return [Boolean, nil] Whether the tool use was successful
      attribute :success, :boolean

      # @return [Integer, nil] Duration in milliseconds
      attribute :duration_ms, :integer

      # @return [String, nil] Provider identifier
      attribute :provider_id, :string

      # Workspace initialization properties

      # @return [Integer, nil] Number of workspace roots
      attribute :root_count, :integer

      # @return [Array<String>, nil] VCS types (e.g. ["git"])
      attribute :vcs_types, Utils::Schema.collection(:string)

      # @return [Boolean, nil] Whether the workspace has multiple roots
      attribute :is_multi_root, :boolean

      # @return [Boolean, nil] Whether the workspace has git
      attribute :has_git, :boolean

      # @return [Boolean, nil] Whether the workspace has mercurial
      attribute :has_mercurial, :boolean

      # @return [Float, nil] Initialization duration in milliseconds
      attribute :init_duration_ms, :float

      # @return [Boolean, nil] Whether feature flags are enabled
      attribute :feature_flag_enabled, :boolean

      # @return [String, nil] Extension version (e.g. "3.0.7")
      attribute :extension_version, :string

      # @return [String, nil] Cline type (e.g. "cli")
      attribute :cline_type, :string

      # @return [String, nil] Platform name (e.g. "cline")
      attribute :platform, :string

      # @return [String, nil] Platform version (e.g. "v24.3.0")
      attribute :platform_version, :string

      # @return [String, nil] Operating system type (e.g. "win32")
      attribute :os_type, :string

      # @return [String, nil] Operating system version (e.g. "Windows 11 Pro")
      attribute :os_version, :string

      # @return [String, nil] Distinct identifier
      attribute :distinct_id, :string

      # @return [String, nil] Whether the session was restored from persistence
      attribute :restored_from_persistence, :boolean

      # All attributes are already snake case
      cline_snake_attributes(*attributes.keys)
    end

    # @!group Public API

    # @return [Integer] Log level number (e.g. 30 for info, 40 for warn)
    attribute :level, :integer

    # @return [String] Timestamp in ISO 8601 format
    attribute :time, :string

    # @return [Integer] Process ID
    attribute :pid, :integer

    # @return [String] Hostname of the machine
    attribute :hostname, :string

    # @return [String] Logger name (e.g. "cline.cli")
    attribute :name, :string

    # @return [String] Component name (e.g. "main")
    attribute :component, :string

    # @return [String] Log message
    attribute :msg, :string

    # @return [Boolean, nil] Whether the session is interactive
    attribute :interactive, :boolean

    # @return [Boolean, nil] Whether a prompt is present
    attribute :has_prompt, :boolean

    # @return [String, nil] Current working directory
    attribute :cwd, :string

    # @return [String, nil] Reason for a fallback or decision
    attribute :reason, :string

    # @return [String, nil] Backend routing mode (e.g. "env-managed", "auto")
    attribute :backend_mode, :string

    # @return [Boolean, nil] Whether the local backend is forced
    attribute :force_local_backend, :boolean

    # @return [String, nil] Telemetry sink name (e.g. "TelemetryLoggerSink")
    attribute :telemetry_sink, :string

    # @return [String, nil] Event name for telemetry entries (e.g. "workspace.initialized")
    attribute :event, :string

    # @return [Properties, nil] Event-specific properties for telemetry entries
    attribute :properties, Properties

    # @return [String, nil] Severity level for error/warn logs (e.g. "error", "warn")
    attribute :severity, :string

    # @return [String, nil] Provider identifier (e.g. "cline")
    attribute :provider_id, :string

    # @return [Error, nil] Error details for error logs
    attribute :err, Error
  end
end
