module Cline
  # Access cached Cline models
  class Models < Utils::Schema.map(Model)
    Serializable::ClineData.include_for(self, 'cache/cline_models.json')
  end
end
