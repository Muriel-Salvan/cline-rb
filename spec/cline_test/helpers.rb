module ClineTest
  module Helpers
    include Cli
    include Config
    include Data
    include Os
    include Task
    include TempDir

    # @return [Boolean] Are we in test debug mode?
    def self.debug?
      ENV['TEST_DEBUG'] == '1'
    end
  end
end
