module Cline
  # Session messages
  class SessionMessages < Schema
    extend Forwardable

    # @!group Public API

    Serializable::ClineData.include_for(self, proc { |base_dir| "#{File.basename(base_dir)}.messages.json" })

    # @return [Integer] Schema version
    attribute :version, :integer

    # @return [String] Last update timestamp of this messages file
    attribute :updated_at, :string

    # @return [String] Agent identifier (lead or agent)
    attribute :agent, :string

    # @return [String] Session ID
    attribute :session_id, :string

    # @return [Array<SessionMessage>] Messages of this session
    attribute :messages, SessionMessage, collection: true

    # @return [String] System prompt used for this session
    attribute :system_prompt, :string

    cline_snake_attributes(*%i[updated_at system_prompt])

    # Delegates enumerating methods to the internal messages
    def_delegators :messages, *%i[[] << each empty? first last size]

    # @!group Internal

    # Parse a Cline JSON object and instantiate the proper instance from it.
    # Handle the following features:
    # * Cline camelCase naming.
    # * Keep track of extra attributes to serialize them back if needed.
    #
    # @param json [String] JSON data
    # @param cline_models [Models] The Cline models used to interpret the tasks' messages
    # @return [Object] Corresponding instance
    def self.from_cline_json(json, cline_models:)
      instance = SessionMessages.of_hash(JSON.parse(json))
      # Shale doesn't pass extra kwargs to nested collection items,
      # so we set cline_models on each message after deserialization
      instance.messages&.each { |message| message.cline_models = cline_models }
      instance
    end
  end
end
