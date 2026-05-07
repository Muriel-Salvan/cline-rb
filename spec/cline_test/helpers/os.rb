module ClineTest
  module Helpers
    module Os
      # Setup the Cline environment to be tested for a given host os.
      # Rollback to the default host OS after.
      #
      # @param host_os [String] The host os
      # @yield Code called with the host OS setup
      def with_host_os(host_os)
        Cline::Utils::Os.class_eval { singleton_class.install_os_methods(host_os:) }
        begin
          yield
        ensure
          Cline::Utils::Os.class_eval { singleton_class.install_os_methods }
        end
      end
    end
  end
end
