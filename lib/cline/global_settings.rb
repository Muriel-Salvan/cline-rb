module Cline
  # Global Cline settings
  class GlobalSettings < Schema
    Utils::SerializableToJson.include_for(self, 'globalState.json')
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
