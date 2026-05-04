require 'fileutils'
require 'json'

module Cline
  # A task defined in a directory
  class Task
    # @!group Public API

    extend Utils::InitializableFromDir

    # Get the task's messages
    #
    # @return [Messages, nil] The task's messages, or nil if none
    def messages
      @messages ||= Messages.json_from_base_dir(@task_dir, cline_models: @cline_models)
    end

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(Task) &&
        other.messages == messages
    end

    # Monitor messages with a callback called when new or updated messages arrive
    #
    # @param on_message [#call] Block called each time there is a new or updated message.
    #   * Param message [Message] Message that has happened
    #   * Param last [Boolean] Is this the last message fetched from the list of messages?
    #   * Param previous_version [Message or nil] Previous version of this message if it got updated, or nil if it is a new one
    # @param ignore_partials [Boolean] Should we ignore partial messages?
    #   If true, then on_message will only be called for messages that have been fully received.
    # @param monitoring_interval_secs [Float] The monitoring interval in seconds
    # @yield [#call] Code called while monitoring is in place
    def monitor_messages(on_message:, ignore_partials: false, monitoring_interval_secs: 1, &)
      # Keep messages per timestamp to detect updates
      messages = {}
      Messages.monitor_changes(
        @task_dir,
        cline_models: @cline_models,
        on_change: proc do |new_messages|
          # Update the messages we have
          @messages = new_messages
          if new_messages && !new_messages.empty?
            # Filter unwanted messages
            new_messages = new_messages.reject(&:partial) if ignore_partials
            # Check for updates in all messages
            last_idx = new_messages.size - 1
            new_messages.each.with_index do |message, idx|
              ts = message.ts
              if message != messages[ts]
                on_message.call(message, idx == last_idx, messages[ts])
                messages[ts] = message
              end
            end
          end
        end,
        monitoring_interval_secs:,
        &
      )
    end

    # @!group Internal

    # Constructor
    #
    # @param cline_models [Models] The Cline models used to interpret the tasks' messages
    def initialize(cline_models:)
      @cline_models = cline_models
    end

    # Initialize this instance from a directory
    #
    # @param dir [String] The directory to be used to initialize this instance
    def initialize_from_dir(dir)
      @task_dir = dir
    end
  end
end
