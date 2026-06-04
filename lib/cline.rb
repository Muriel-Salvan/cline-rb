require 'zeitwerk'

Zeitwerk::Loader.for_gem.setup

# All Cline objects are accessible here.
module Cline
  class << self
    # Configure the behaviour of the cline-rb Rubygem
    #
    # @yield [config] The configuration
    def configure
      yield config
    end

    # @return [Configuration] The cline-rb Rubygem configuration
    def config
      @config ||= Configuration.new
    end
  end
end
