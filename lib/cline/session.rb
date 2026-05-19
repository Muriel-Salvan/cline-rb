module Cline
  # A session defined in a directory
  class Session
    extend Forwardable

    # @!group Public API

    include Serializable::Dir

    # Delegates all data attributes to the data object
    def_delegators :data, *SessionData.attributes.keys

    # Get the session's data
    #
    # @param create [Boolean] Should the data be created if it does not exist?
    # @return [SessionData, nil] The session's data, or nil if none
    def data(create: self.create)
      @data ||= SessionData.from_cline_data(dir, create:)
    end

    # Get the session's messages
    #
    # @param create [Boolean] Should the messages be created if they don't exist?
    # @return [SessionMessages, nil] The session's messages, or nil if none
    def messages(create: self.create)
      @messages ||= SessionMessages.from_cline_data(dir, cline_models: @cline_models, create:)
    end

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(Session) &&
        other.data == data
    end

    # Monitor messages with a callback called when new or updated messages arrive
    #
    # @param on_message [#call] Block called each time there is a new or updated message.
    #   * Param message [SessionMessage] Message that has happened
    #   * Param last [Boolean] Is this the last message fetched from the list of messages?
    #   * Param previous_version [SessionMessage or nil] Previous version of this message if it got updated, or nil if it is a new one
    # @param monitoring_interval_secs [Float] The monitoring interval in seconds
    # @yield Optional code called while monitoring is in place.
    #   If used then monitoring is stopped at the end of the block's execution.
    # @return [FileMonitor, nil] If no block has been given, return the monitor that needs to be
    #   stopped by the caller when monitoring should end.
    def monitor_messages(on_message:, monitoring_interval_secs: 1, &)
      # Keep messages per timestamp to detect updates
      messages = {}
      SessionMessages.monitor_cline_data_changes(
        dir,
        cline_models: @cline_models,
        on_change: proc do |new_messages|
          # Update the messages we have
          @messages = new_messages
          if new_messages&.messages && !new_messages.messages.empty?
            # Check for updates in all messages
            last_idx = new_messages.messages.size - 1
            new_messages.messages.each.with_index do |message, idx|
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
  end
end
