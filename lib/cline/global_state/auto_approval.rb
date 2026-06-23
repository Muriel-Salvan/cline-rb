module Cline
  class GlobalState
    # Auto approval and command execution permissions
    module AutoApproval
      # Auto approval action toggles
      class AutoApprovalActions < Schema
        # @return [Boolean] Allow reading files
        attribute :read_files, :boolean

        # @return [Boolean] Allow reading files externally
        attribute :read_files_externally, :boolean

        # @return [Boolean] Allow editing files
        attribute :edit_files, :boolean

        # @return [Boolean] Allow editing files externally
        attribute :edit_files_externally, :boolean

        # @return [Boolean] Allow executing safe commands
        attribute :execute_safe_commands, :boolean

        # @return [Boolean] Allow executing all commands
        attribute :execute_all_commands, :boolean

        # @return [Boolean] Allow using browser tools
        attribute :use_browser, :boolean

        # @return [Boolean] Allow using MCP servers
        attribute :use_mcp, :boolean
      end

      # Auto approval configuration settings
      class AutoApprovalSettings < Schema
        # @return [AutoApprovalActions] Action toggles
        attribute :actions, AutoApprovalActions

        # @return [Boolean] Auto approval enabled flag
        attribute :enabled, :boolean

        # @return [Integer] Configuration version
        attribute :version, :integer

        # @return [Array<String>] Favorite approval entries
        attribute :favorites, Utils::Schema.collection(:string)

        # @return [Integer] Maximum allowed requests
        attribute :max_requests, :integer

        # @return [Boolean] Enable notifications
        attribute :enable_notifications, :boolean
      end

      # Define all the attributes of the included class
      #
      # @param base [Class] Base class including this mixin
      def self.included(base)
        base.class_eval do
          # @return [AutoApprovalSettings] Auto approval configuration settings
          attribute :auto_approval_settings, AutoApprovalSettings

          # @return [Boolean] YOLO mode toggled flag
          attribute :yolo_mode_toggled, :boolean
        end
      end
    end
  end
end
