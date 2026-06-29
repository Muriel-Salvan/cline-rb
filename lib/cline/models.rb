module Cline
  # Base class, dynamically defined
  ModelMap = Utils::Schema.map(Model)

  # Access cached Cline models
  class Models < ModelMap
    # @!group Public API

    Serializable::ClineData.include_for(self, 'cache/cline_models.json')
  end
end
