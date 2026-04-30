module Cline
  class GlobalSettings
    # Toggles configuration of rules, workflows and skills
    module Toggles
      # Define all the attributes of the included class
      #
      # @param base [Class] Base class including this mixin
      def self.included(base)
        base.class_eval do
          # @return [Hash] Remote rules toggle states
          attribute :remote_rules_toggles, Utils::Schema.map(:boolean)

          # @return [Hash] Remote workflow toggle states
          attribute :remote_workflow_toggles, Utils::Schema.map(:boolean)

          # @return [Hash] Global workflow toggle states
          attribute :global_workflow_toggles, Utils::Schema.map(:boolean)

          # @return [Hash] Global Cline rules toggle states
          attribute :global_cline_rules_toggles, Utils::Schema.map(:boolean)

          # @return [Hash] Remote skills toggle states
          attribute :remote_skills_toggles, Utils::Schema.map(:boolean)

          # @return [Hash] Global skills toggle states
          attribute :global_skills_toggles, Utils::Schema.map(:boolean)
        end
      end
    end
  end
end
