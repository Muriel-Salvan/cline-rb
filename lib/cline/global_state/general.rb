module Cline
  class GlobalState
    # General UI, telemetry and user preferences
    module General
      # Dismissed banner entry
      class DismissedBanner < Schema
        # @return [String] Banner identifier
        attribute :banner_id, :string

        # @return [Integer] Timestamp when banner was dismissed
        attribute :dismissed_at, :integer
      end

      # Define all the attributes of the included class
      #
      # @param base [Class] Base class including this mixin
      def self.included(base)
        base.class_eval do
          # @return [Boolean] Flag indicating welcome view has been completed
          attribute :welcome_view_completed, :boolean

          # @return [String] Custom system prompt text
          attribute :custom_prompt, :string

          # @return [String] Default terminal profile identifier
          attribute :default_terminal_profile, :string

          # @return [String] Telemetry collection preference
          attribute :telemetry_setting, :string

          # @return [String] OCA mode setting
          attribute :oca_mode, :string

          # @return [String] Current Cline version
          attribute :cline_version, :string

          # @return [String] Last shown announcement identifier
          attribute :last_shown_announcement_id, :string

          # @return [String] VS Code terminal execution mode
          attribute :vscode_terminal_execution_mode, :string

          # @return [Boolean] New user flag
          attribute :is_new_user, :boolean

          # @return [String] MCP display mode
          attribute :mcp_display_mode, :string

          # @return [Integer] Last dismissed info banner version
          attribute :last_dismissed_info_banner_version, :integer

          # @return [Integer] Last dismissed model banner version
          attribute :last_dismissed_model_banner_version, :integer

          # @return [Integer] Last dismissed CLI banner version
          attribute :last_dismissed_cli_banner_version, :integer

          # @return [Array<DismissedBanner>] List of dismissed banners
          attribute :dismissed_banners, Utils::Schema.collection(DismissedBanner)

          # @return [Integer] Terminal output line limit
          attribute :terminal_output_line_limit, :integer

          # @return [Boolean] Opt out of remote configuration flag
          attribute :opt_out_of_remote_config, :boolean

          # @return [Integer] VS Code migration version
          attribute :__vscode_migration_version, :integer
        end
      end
    end
  end
end
