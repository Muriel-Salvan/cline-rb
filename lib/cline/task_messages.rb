module Cline
  # Base class, dynamically defined
  TaskMessageCollection = Utils::Schema.collection(TaskMessage)

  # Access all messages associated to a Cline task
  class TaskMessages < TaskMessageCollection
    # @!group Public API

    Serializable::ClineData.include_for(self, 'ui_messages.json')
  end
end
