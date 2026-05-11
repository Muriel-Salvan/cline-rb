require 'os'

module Cline
  module Utils
    # Provide OS-specific helpers
    module Os
      class << self
        # @return [String] The Host OS that has been installed
        attr_accessor :installed_host_os

        # Install OS-specific methods in this module
        #
        # @param host_os [String] Host OS for which we install the methods
        def self.install_os_methods(host_os: OS.host_os)
          # Auto-extend with correct OS implementation at load time
          require_relative "os/#{host_os}.rb"
          host_os_module = Os.const_get(host_os.split('_').map(&:capitalize).join.to_sym)
          Os.installed_host_os = host_os
          # Clean eventually other methods that were installed before
          host_os_module.instance_methods.each do |method|
            undef_method(method) if method_defined?(method)
            define_method(method, host_os_module.instance_method(method))
          end
        end

        # Install the OS-specific methods
        install_os_methods
      end
    end
  end
end
