module Cline
  # Global settings for Cline
  class GlobalSettings < Schema
    Serializable::ClineData.include_for(self, 'settings/global-settings.json')

    # @return [Boolean] Flag indicating if automatic updates are enabled
    attribute :auto_update_enabled, :boolean

    # @return [Boolean] Flag indicating if telemetry is opted out
    attribute :telemetry_opt_out, :boolean

    # @return [Array<String>] List of tools that are disabled
    attribute :disabled_tools, :string, collection: true
  end
end
