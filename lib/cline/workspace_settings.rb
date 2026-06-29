module Cline
  # Workspace settings from workspaceState.json
  class WorkspaceSettings < Schema
    # @!group Public API

    Serializable::ClineData.include_for(self, 'workspaceState.json')

    # @return [Hash{String => Boolean}] Local skills toggle states
    attribute :local_skills_toggles, Utils::Schema.map(:boolean)

    # @return [Hash{String => Boolean}] Local Cline rules toggle states
    attribute :local_cline_rules_toggles, Utils::Schema.map(:boolean)

    # @return [Hash{String => Boolean}] Local Agents rules toggle states
    attribute :local_agents_rules_toggles, Utils::Schema.map(:boolean)

    # @return [Hash{String => Boolean}] Workflow toggle states
    attribute :workflow_toggles, Utils::Schema.map(:boolean)

    # @return [Hash{String => Boolean}] Local Windsurf rules toggle states
    attribute :local_windsurf_rules_toggles, Utils::Schema.map(:boolean)

    # @return [Hash{String => Boolean}] Local Cursor rules toggle states
    attribute :local_cursor_rules_toggles, Utils::Schema.map(:boolean)

    # @return [Integer] VSCode migration version
    attribute :__vscode_migration_version, :integer
  end
end
