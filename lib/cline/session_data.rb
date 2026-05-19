module Cline
  # Session data
  class SessionData < Schema
    Serializable::ClineData.include_for(self, proc { |base_dir| "#{File.basename(base_dir)}.json" })

    # Session metadata
    class Metadata < Schema
      # Checkpoint metadata
      class Checkpoint < Schema
        # Checkpoint entry (ref, timestamps, etc.)
        class CheckpointEntry < Schema
          # @return [String] Git ref of the checkpoint
          attribute :ref, :string

          # @return [Integer] Timestamp when the checkpoint was created
          attribute :created_at, :integer

          # @return [Integer] Number of runs for this checkpoint
          attribute :run_count, :integer

          # @return [String] Kind of checkpoint (e.g. "stash")
          attribute :kind, :string
        end

        # @return [CheckpointEntry] Latest checkpoint entry
        attribute :latest, CheckpointEntry

        # @return [Array<CheckpointEntry>] History of checkpoint entries
        attribute :history, CheckpointEntry, collection: true
      end

      # Usage statistics
      class Usage < Schema
        # @return [Integer] Input tokens count
        attribute :input_tokens, :integer

        # @return [Integer] Output tokens count
        attribute :output_tokens, :integer

        # @return [Integer] Cache read tokens count
        attribute :cache_read_tokens, :integer

        # @return [Integer] Cache write tokens count
        attribute :cache_write_tokens, :integer

        # @return [Float] Total cost of the API call
        attribute :total_cost, :float
      end

      # @return [Checkpoint] Checkpoint information
      attribute :checkpoint, Checkpoint

      # @return [String] Title of the session
      attribute :title, :string

      # @return [Float] Total cost of the session
      attribute :total_cost, :float

      # @return [Float] Aggregated agents cost
      attribute :aggregated_agents_cost, :float

      # @return [Usage] Usage statistics
      attribute :usage, Usage

      # @return [Usage] Aggregate usage statistics
      attribute :aggregate_usage, Usage
    end

    # @return [Integer] Version number
    attribute :version, :integer

    # @return [String] Unique session identifier
    attribute :session_id, :string

    # @return [String] Source of the session (e.g. "cli")
    attribute :source, :string

    # @return [Integer] Process ID
    attribute :pid, :integer

    # @return [String] Start time of the session (ISO 8601)
    attribute :started_at, :string

    # @return [String] End time of the session (ISO 8601)
    attribute :ended_at, :string

    # @return [Integer] Exit code of the process
    attribute :exit_code, :integer

    # @return [String] Session status (e.g. "completed")
    attribute :status, :string

    # @return [Boolean] Whether the session is interactive
    attribute :interactive, :boolean

    # @return [String] Provider name (e.g. "cline")
    attribute :provider, :string

    # @return [String] Model name (e.g. "deepseek/deepseek-v4-flash")
    attribute :model, :string

    # @return [String] Current working directory
    attribute :cwd, :string

    # @return [String] Workspace root path
    attribute :workspace_root, :string

    # @return [String] Team name
    attribute :team_name, :string

    # @return [Boolean] Whether tools are enabled
    attribute :enable_tools, :boolean

    # @return [Boolean] Whether spawn is enabled
    attribute :enable_spawn, :boolean

    # @return [Boolean] Whether teams are enabled
    attribute :enable_teams, :boolean

    # @return [String] Prompt for the session
    attribute :prompt, :string

    # @return [Metadata] Session metadata
    attribute :metadata, Metadata

    # @return [String] Path to the messages file
    attribute :messages_path, :string

    cline_snake_attributes(
      *%i[
        session_id
        started_at
        ended_at
        exit_code
        workspace_root
        team_name
        enable_tools
        enable_spawn
        enable_teams
        messages_path
      ]
    )
  end
end
