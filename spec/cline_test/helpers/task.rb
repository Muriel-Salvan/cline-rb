module ClineTest
  module Helpers
    module Task
      # Provide a test task
      #
      # @param name [String] The task name
      # @param messages [Array<Hash>, nil] The task messages, or nil if none
      # @param cline_models [Hash{String => Hash}, nil] The Cline models to create, or nil if none
      # @param create [Boolean] Should the data be instantiated with the create option?
      # @yield [task] Block called with the test task ready
      # @yieldparam [Cline::Task] The test task
      def with_task(name: 'test-task', messages: nil, cline_models: nil, create: false)
        with_data(
          tasks: {
            name => {
              messages:
            }
          },
          cline_models:,
          create:
        ) do |data|
          yield data.tasks[name]
        end
      end
    end
  end
end
