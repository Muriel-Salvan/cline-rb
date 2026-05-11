require 'os'
require 'sys/proctable'

module ClineTest
  module Helpers
    module Os
      # Get the list of possible OSes that our tests should be compatible with.
      # Some test suites can loop over those values to make sure all tests pass on all possible OSes.
      # The values are taken from OS.host_os possible values.
      #
      # @return [Array<String>] The list of host OSes
      def self.possible_oses
        %w[
          linux
          mingw32
        ]
      end

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

      # Spy killing processes, and remember all PIDs that have been killed in a killed_pids accessor.
      #
      # @param on_kill [#call, nil] Callback called before killing the process, or nil if none
      #   * Param pid [String] The PID that is going to be killed
      def spy_killing_pids(on_kill: nil)
        @killed_pids = []
        case Cline::Utils::Os.installed_host_os
        when 'linux'
          allow(Process).to receive(:kill).and_wrap_original do |original_kill, signal, pid|
            if signal == 'TERM'
              real_kill(pid, on_kill:)
            else
              original_kill.call(signal, pid)
            end
          end
        when 'mingw32'
          allow(Cline::Utils::Os).to receive(:system).and_wrap_original do |original_system, cmd, **kwargs|
            if cmd =~ %r{^taskkill /f /pid (\d+)$}
              pid = Integer(Regexp.last_match(1))
              real_kill(pid, on_kill:)
            else
              original_system.call(cmd, **kwargs)
            end
          end
        else
          raise "Unsupported host OS in tests: #{Cline::Utils::Os.installed_host_os}"
        end
      end

      # @return [Array<Integer>] The PIDs that have been killed
      attr_reader :killed_pids

      # OS-agnostic kill that will work while stubbing OS-specific kills
      #
      # @param pid [Integer] The PID to kill
      # @param on_kill [#call, nil] Callback called before killing the process, or nil if none (see #spy_killing_pids)
      def real_kill(pid, on_kill: nil)
        on_kill&.call(pid)
        @killed_pids << pid
        case OS.host_os
        when 'linux'
          Process.kill('TERM', pid)
        when 'mingw32'
          system("taskkill /f /pid #{pid} 1>nul 2>&1")
        else
          raise "Unsupported tests host OS: #{OS.host_os}"
        end
      end

      # Get all child PIDs recursively for a given parent PID
      #
      # @param parent_pid [Integer] Parent process ID
      # @return [Array<Integer>] All child and grandchild PIDs recursively
      def get_child_pids_recursive(parent_pid)
        child_pids = []
        Sys::ProcTable.ps.each do |process|
          next unless process.ppid == parent_pid

          child_pids << process.pid
          child_pids.concat(get_child_pids_recursive(process.pid))
        end
        child_pids
      end
    end
  end
end
