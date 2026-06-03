module Cline
  # Global Cline state
  class GlobalState < Schema
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
