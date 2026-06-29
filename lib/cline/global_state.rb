module Cline
  # Global Cline state
  class GlobalState < Schema
    # @!group Public API

    Serializable::ClineData.include_for(self, 'globalState.json')
    include Models
    include AutoApproval
    include Browser
    include Workspace
    include Features
    include ApiProviders
    include General
    include Toggles
  end
end
