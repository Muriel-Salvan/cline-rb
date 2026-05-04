require 'json'

module Cline
  # Access all messages associated to a Cline task
  class Messages
    extend Forwardable

    # @!group Public API

    Utils::SerializableToJson.include_for(self, 'ui_messages.json')
    include Enumerable

    # Delegates enumerating methods to the internal messages
    def_delegators :messages, :each, :size, :[], :empty?

    # Equality check
    #
    # @param other [Object] The other to check equality with
    # @return [Boolean] True if objects are equal
    def ==(other)
      other.is_a?(Messages) &&
        other.messages == messages
    end

    # @!group Internal

    # Constructor
    #
    # @param messages [Array<Message>] List of messages
    def initialize(messages)
      @messages = messages
    end

    # Parse a Cline JSON object and instantiate the proper instance from it.
    # Handle the following features:
    # * Cline camelCase naming.
    # * Keep track of extra attributes to serialize them back if needed.
    #
    # @param json [String] JSON data
    # @param cline_models [Models] The Cline models used to interpret the tasks' messages
    # @return [Object] Corresponding instance
    def self.from_cline_json(json, cline_models:)
      Messages.new(JSON.parse(json).map { |json_message| Message.of_hash(json_message, cline_models:) })
    end

    # Output this object as Cline JSON.
    #
    # @return [String] Cline JSON
    def to_cline_json
      map { |message| Message.as_hash(message) }.to_json
    end

    protected

    # @return [Array<Message>] List of messages
    attr_reader :messages
  end
end
