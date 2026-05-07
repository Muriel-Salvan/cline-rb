require 'os'

module Cline
  module Utils
    # Provide OS-specific helpers
    module Os
      class << self
        # Install OS-specific methods in this module
        #
        # @param host_os [String] Host OS for which we install the methods
        def self.install_os_methods(host_os: OS.host_os)
          # Auto-extend with correct OS implementation at load time
          require_relative "os/#{host_os}.rb"
          host_os_module = Os.const_get(host_os.split('_').map(&:capitalize).join.to_sym)
          # Clean eventually other methods that were installed before
          host_os_module.instance_methods.each do |method|
            undef_method(method) if method_defined?(method)
          end
          prepend host_os_module
        end

        # Install the OS-specific methods
        install_os_methods
      end
    end
  end
end
