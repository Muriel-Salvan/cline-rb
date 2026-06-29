module Cline
  # Providers configuration stored in settings/providers.json
  class Providers < Schema
    # @!group Public API

    Serializable::ClineData.include_for(self, 'settings/providers.json')

    # A provider entry with settings, update timestamp and token source
    class ProviderEntry < Schema
      # @!group Public API

      # Settings for a single provider entry
      class ProviderSettings < Schema
        # @!group Public API

        # Settings specific to a provider's reasoning configuration
        class ReasoningSettings < Schema
          # @!group Public API

          # @return [Boolean] Whether reasoning is enabled
          attribute :enabled, :boolean

          # @return [String] The reasoning effort level (e.g. "xhigh")
          attribute :effort, :string
        end

        # @return [String] The provider name
        attribute :provider, :string

        # @return [SecretString, nil] The API key for this provider
        attribute :api_key, SecretString

        # @return [String] The model identifier
        attribute :model, :string

        # @return [ReasoningSettings, nil] Optional reasoning configuration
        attribute :reasoning, ReasoningSettings
      end

      # @return [ProviderSettings] The provider settings
      attribute :settings, ProviderSettings

      # @return [String] The timestamp when this provider was last updated
      attribute :updated_at, :string

      # @return [String] The token source (e.g. "manual")
      attribute :token_source, :string
    end

    # @return [Integer] The version of the providers configuration
    attribute :version, :integer

    # @return [String] The last used provider identifier
    attribute :last_used_provider, :string

    # @return [Hash] The map of provider entries keyed by provider name
    attribute :providers, Utils::Schema.map(ProviderEntry)
  end
end
