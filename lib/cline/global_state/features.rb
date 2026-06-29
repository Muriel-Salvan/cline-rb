module Cline
  class GlobalState
    # Feature flags and experimental features
    module Features
      # Focus chain feature settings
      class FocusChainSettings < Schema
        # @!group Public API

        # @return [Boolean] Focus chain enabled flag
        attribute :enabled, :boolean

        # @return [Integer] Reminder interval in messages
        attribute :remind_cline_interval, :integer
      end

      # Define all the attributes of the included class
      #
      # @param base [Class] Base class including this mixin
      def self.included(base)
        base.class_eval do
          # @!group Public API

          # @return [FocusChainSettings] Focus chain feature settings
          attribute :focus_chain_settings, FocusChainSettings

          # @return [Boolean] Flag enabling Cline web tools
          attribute :cline_web_tools_enabled, :boolean

          # @return [Boolean] Flag enabling double check before completion
          attribute :double_check_completion_enabled, :boolean

          # @return [Boolean] Flag enabling parallel tool execution
          attribute :enable_parallel_tool_calling, :boolean

          # @return [Boolean] Flag enabling strict Plan mode enforcement
          attribute :strict_plan_mode_enabled, :boolean

          # @return [Boolean] Flag enabling subagents feature
          attribute :subagents_enabled, :boolean

          # @return [Boolean] Flag enabling auto content condensation
          attribute :use_auto_condense, :boolean

          # @return [Boolean] Flag enabling native tool calling
          attribute :native_tool_call_enabled, :boolean

          # @return [Boolean] Checkpoints feature enabled flag
          attribute :enable_checkpoints_setting, :boolean

          # @return [Boolean] Background edit enabled flag
          attribute :background_edit_enabled, :boolean
        end
      end
    end
  end
end
