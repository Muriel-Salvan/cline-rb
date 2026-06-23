module Cline
  # Access all messages associated to a Cline task
  class TaskMessages < Utils::Schema.collection(TaskMessage)
    Serializable::ClineData.include_for(self, 'ui_messages.json')
  end
end
