module Cline
  # Track usage statistics associated to a message
  Usage = Struct.new(
    # @!group Public API

    # [Float] Monetary cost incurred for this API request
    :cost,

    # [Integer] Total input tokens sent in the request
    :input_tokens,

    # [Integer] Total output tokens generated in the response
    :output_tokens,

    # [Integer] Number of tokens retrieved from cache
    :cache_read_tokens,

    # [Integer] Number of tokens stored into cache
    :cache_write_tokens,

    # [Model. nil] Model used for this request, or nil if none
    :cline_model,
    keyword_init: true
  ) do
    # @!group Public API

    # @return [Integer] Total context tokens consumed
    def context_tokens
      input_tokens + output_tokens + cache_read_tokens + cache_write_tokens
    end

    # @return [Integer, nil] Maximum context window limit for the used model
    def context_tokens_limit
      cline_model&.context_window
    end
  end
end
