require 'os'
require 'sys/proctable'

module ClineTest
  module Helpers
    module Os
      class << self
        # @return [#call] The original Process.kill method
        #   Capture the original Process.kill as it is used to kill for real, but it can also be mocked by some test cases.
        attr_accessor :original_process_kill

        # Get the list of possible OSes that our tests should be compatible with.
        # Some test suites can loop over those values to make sure all tests pass on all possible OSes.
        # The values are taken from OS.host_os possible values.
        #
        # @return [Array<String>] The list of host OSes
        def possible_oses
          %w[
            linux
            mingw32
          ]
        end
      end
      Os.original_process_kill = Process.method(:kill)

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

      # Mock needed system calls to make sure OS-specific behaviour works on our tests running in any OS.
      # Use Cline::Utils::Os.installed_host_os to know which OS needs to be mocked.
      # What this does:
      # - Remove any singleton cache of methods from Cline::Utils::Os.
      # - Mock any system call done in methods from Cline::Utils::Os (``, system...).
      # - Spy killing processes, and remember all PIDs that have been killed in a killed_pids accessor.
      #
      # @param user_home_dir [String] The user home directory
      # @param on_kill [#call, nil] Callback called before killing the process, or nil if none
      #   * Param pid [String] The PID that is going to be killed
      def mock_installed_os(user_home_dir: '.cline_test/user_home', on_kill: nil)
        @killed_pids = []
        case Cline::Utils::Os.installed_host_os
        when 'linux'
          %i[
            @user_home_dir
            @max_cmd_length
          ].each do |cache_var|
            Cline::Utils::Os.remove_instance_variable(cache_var) if Cline::Utils::Os.instance_variable_defined?(cache_var)
          end
          allow(Cline::Utils::Os).to receive(:`).with('eval echo ~$USER').and_return(user_home_dir)
          allow(Cline::Utils::Os).to receive(:`).with('getconf ARG_MAX').and_return("100\n")
          allow(Process).to receive(:kill).and_wrap_original do |original_kill, signal, pid|
            if signal == 'TERM'
              real_kill(pid, on_kill:)
            else
              original_kill.call(signal, pid)
            end
          end
        when 'mingw32'
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('USERPROFILE').and_return(user_home_dir)
          allow(Cline::Utils::Os).to receive(:`).with('where cline.cmd').and_return('test/path/to/node')
          allow(Cline::Utils::Os).to receive(:system).and_wrap_original do |original_system, cmd, **kwargs|
            if cmd =~ %r{^taskkill /f /pid (\d+)$}
              pid = Integer(Regexp.last_match(1))
              begin
                real_kill(pid, on_kill:)
              rescue Errno::ESRCH
                # On Windows missing PIDs are errors that are ignored, because a simple system call is used
              end
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

      private

      # OS-agnostic kill that will work while stubbing OS-specific kills
      #
      # @param pid [Integer] The PID to kill
      # @param on_kill [#call, nil] Callback called before killing the process, or nil if none (see #mock_installed_os)
      def real_kill(pid, on_kill: nil)
        on_kill&.call(pid)
        @killed_pids << pid
        case OS.host_os
        when 'linux'
          Os.original_process_kill.call('TERM', pid)
        when 'mingw32'
          system("taskkill /f /pid #{pid} 1>nul 2>&1")
        else
          raise "Unsupported tests host OS: #{OS.host_os}"
        end
      end
    end
  end
end
