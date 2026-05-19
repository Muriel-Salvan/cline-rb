require 'human_number'
require 'open3'
require 'sys/proctable'
require 'tmpdir'

module Cline
  # Provide a wrapper over the Cline CLI tool
  class Cli
    include Utils::Logger

    # Unexpected exit status error
    class UnexpectedExitStatusError < RuntimeError
    end

    # Unknown option
    class UnknownOptionError < RuntimeError
    end

    # Define all commands and their options
    COMMANDS = {
      # Global options
      global: {
        verbose: '--verbose',
        cwd: '--cwd STRING',
        config: '--config STRING'
      },
      auth: {
        # Provider ID for quick setup (e.g., openai-native, anthropic, moonshot)
        provider: '--provider STRING',
        # API key for the provider
        apikey: '--apikey STRING',
        # Model ID to configure (e.g., gpt-4o, claude-sonnet-4-6, kimi-k2.5)
        modelid: '--modelid STRING',
        # Base URL (optional, only for openai provider)
        baseurl: '--baseurl STRING'
      },
      task: {
        # Run in act mode
        act: '--act',
        # Run in plan mode
        plan: '--plan',
        # Enable yolo mode (auto-approve actions)
        yolo: '--yolo',
        # Enable auto-approve all actions while keeping interactive mode
        auto_approve_all: '--auto-approve-all',
        # Optional timeout in seconds (applies only when provided)
        timeout: '--timeout INTEGER',
        # Model to use for the task
        model: '--model STRING',
        # Enable extended thinking (1024 tokens when enabled without value)
        thinking: '--thinking INTEGER',
        # Reasoning effort: none|low|medium|high|xhigh
        reasoning_effort: '--reasoning-effort STRING',
        # Maximum consecutive mistakes before halting in yolo mode
        max_consecutive_mistakes: '--max-consecutive-mistakes INTEGER',
        # Output messages as JSON instead of styled text
        json: '--json',
        # Reject first completion attempt to force re-verification
        double_check_completion: '--double-check-completion',
        # Enable AI-powered context compaction instead of mechanical truncation
        auto_condense: '--auto-condense',
        # Path to additional hooks directory for runtime hook injection
        hooks_dir: '--hooks-dir STRING',
        # Task ID to resume, or nil for a new task
        task_id: '--taskId STRING'
      }
    }

    # Constructor
    #
    # @param stdout_echo [Boolean] Do we echo stdout of Cline CLI?
    # @param kwargs [Hash{Symbol => Object}] Global options (see COMMANDS[:global])
    def initialize(stdout_echo: false, **kwargs)
      @global_options = parse_global_options(**kwargs)
      @stdout_echo = stdout_echo
      @config_dir = kwargs[:config]
      @cline_pid = nil
    end

    # Authenticate the CLI
    #
    # @param kwargs [Hash{Symbol => Object}] Command options (see COMMANDS)
    # @return [Hash{Symbol => Object}] A set of return properties (see #run_cli)
    def auth(**kwargs)
      run_cli(command: 'auth', args: parse_auth_options(**kwargs))
    end

    # Run a task with a prompt
    #
    # @param prompt [String] The prompt to give to the task
    # @param on_message [#call, nil] Callback called for each new or updated message for this task, or nil if none (see Task#monitor_message)
    # @param monitoring_interval_secs [Float] The monitoring interval in seconds
    # @param kwargs [Hash{Symbol => Object}] Command options (see COMMANDS)
    # @return [Hash{Symbol => Object}] A set of return properties (see #run_cli). Additionnally the following ones:
    #   * message [TaskMessage, nil] The last message of the task, or nil if none
    def task(prompt, on_message: nil, monitoring_interval_secs: 1, **kwargs)
      task_monitor_thread = nil
      @current_task = nil
      cli_running = true
      begin
        result = run_cli(
          args: parse_task_options(**kwargs),
          stdin_data: prompt,
          on_stdout: proc do |line|
            if line.strip =~ /^\{"type":"task_started","taskId":"([^"]+)"\}$/
              task_id = Regexp.last_match[1]
              log_debug "Started task ID #{task_id}"
              # Create the thread that will find out the task handled by the CLI
              task_monitor_thread = Thread.new do
                # It can be that the task has not been created yet.
                # Just wait for it.
                while cli_running
                  if config.tasks
                    break if config.tasks[task_id]

                    config.tasks.refresh!
                  else
                    config.refresh!
                  end
                  sleep 0.1
                end
                # The CLI could be already finished, but we still need to monitor the eventual messages.
                @current_task = config&.tasks && config.tasks[task_id]
                log_debug 'Found task correctly' if @current_task
                # [Hash{Integer => Usage}] All usages, per timestamp, for logging purposes
                usages = {}
                @current_task&.monitor_messages(
                  on_message: proc do |message, last, previous_version|
                    log_debug do
                      usages[message.ts] = message.usage if message.usage
                      last_usage = usages.values.last
                      prefix = "[#{message.timestamp.strftime('%H:%M:%S')}]#{
                        unless last_usage.nil?
                          " (#{HumanNumber.currency(usages.values.map { |usage| usage.cost || 0.0 }.sum, currency_code: 'USD')}" \
                            " #{HumanNumber.human_number(last_usage.context_tokens, max_digits: 2)}" \
                            "/#{HumanNumber.human_number(last_usage.context_tokens_limit, max_digits: 2)})"
                        end
                      } - "
                      "#{prefix}#{message.to_human(limit: 128 - prefix.size)}"
                    end
                    # Call the user callback if any
                    on_message&.call(message, last, previous_version)
                    # Interrupt the CLI if we just got a last message that is blocking (like a user ask or plan_mode_respond).
                    if last && (
                      (message.type == 'ask' && %w[followup new_task plan_mode_respond].include?(message.ask)) ||
                      (message.type == 'say' && %w[completion_result].include?(message.say))
                    )
                      # The CLI should end.
                      # Maybe it did it already, but maybe not. Make sure it does.
                      interrupt
                    end
                  end,
                  ignore_partials: true,
                  monitoring_interval_secs:
                ) do
                  sleep 0.1 while cli_running
                end
              end
            end
          end
        )
      ensure
        cli_running = false
        task_monitor_thread&.join
      end
      result[:message] = @current_task&.messages&.last
      result
    end

    # @return [Integer, nil] The PID of the running Cline process, if any
    attr_reader :cline_pid

    # @return [Task, nil] The current or last task handled by the Cline process, if any
    attr_reader :current_task

    # Interrupt the running Cline command
    def interrupt
      if cline_pid
        log_debug "Interrupt current command with PID #{cline_pid}"
        all_pids = [cline_pid] + get_child_pids_recursive(cline_pid)
        log_debug "Found process tree PIDs: #{all_pids.join(', ')}"
        @interrupted_on_purpose = true
        all_pids.reverse.each do |pid|
          log_debug "Kill process #{pid}"
          Utils::Os.kill(pid)
        end
      else
        log_debug 'No Cline command started, so no need to interrupt anything'
      end
    end

    private

    # Generate all methods that can parse kwargs to generate CLI options, for each known command.
    # Those methods are named parse_#{command}_options.
    COMMANDS.each do |command, options|
      # Parse the options for a given command
      #
      # @param kwargs [Hash{Symbol => Object}] The options associated to the command
      # @return [Array<String>] The corresponding CLI arguments
      define_method(:"parse_#{command}_options") do |**kwargs|
        kwargs.map do |option, value|
          raise UnknownOptionError, "Unknown #{command} option #{option}" unless options.key?(option)

          if value
            cli_option, cli_arg = options[option].split
            "#{cli_option}#{" #{value}" unless cli_arg.nil?}"
          end
        end.compact
      end
    end

    # Run a command on the Cline CLI
    #
    # @param command [Symbol, nil] The command to run, or nil if none
    # @param args [Array<String>] Command arguments
    # @param stdin_data [String, nil] Data to send to the standard input of the CLI, or nil if none
    # @param expected_exit_status [Integer, nil] Expected exit status, or nil for no expectation
    # @param on_stdout [#call, nil] Optional callback that is called for every line output on stdout
    #   * Param line [String] The stdout line (including potential \n)
    # @return [Hash{Symbol => Object}] A set of return properties:
    #   * stdout [String] Full stdout
    #   * stderr [String] Full stderr
    #   * exit_status [Integer] Exit status
    def run_cli(command: nil, args: [], stdin_data: nil, expected_exit_status: 0, on_stdout: nil)
      cmd = "cline#{" #{command}" if command} #{(@global_options + args).join(' ')}".strip
      (
        proc do |&run_block|
          if stdin_data
            Dir.mktmpdir do |tmp_dir|
              stdin_file = "#{tmp_dir}/stdin"
              File.write(stdin_file, stdin_data)
              cmd << " < #{stdin_file}"
              run_block.call
            end
          else
            run_block.call
          end
        end
      ).call do
        log_debug "Launch CLI `#{cmd}`..."
        @interrupted_on_purpose = false
        stdout_lines = []
        stderr_lines = []
        exit_status = nil
        Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
          @cline_pid = wait_thr.pid
          log_debug "Cline process started with PID #{@cline_pid}"
          stdin.close
          [
            # Parse stdout
            Thread.new do
              stdout.each_line do |line|
                stdout_lines << line
                $stdout.write(line) if @stdout_echo
                on_stdout&.call(line)
              end
            end,
            # Parse stderr
            Thread.new do
              stderr.each_line do |line|
                stderr_lines << line
                $stderr.write(line)
              end
            end
          ].each(&:join)
          exit_status = wait_thr.value.exitstatus
          log_debug "Cline process `#{cmd}` with PID #{@cline_pid} exited with status: #{exit_status}#{' (interrupted on purpose)' if @interrupted_on_purpose}"
          @cline_pid = nil
          if !@interrupted_on_purpose && !expected_exit_status.nil? && exit_status != expected_exit_status
            raise UnexpectedExitStatusError, "CLI `#{cmd}` exited with status #{exit_status} (expected #{expected_exit_status})"
          end
        end
        {
          stdout: stdout_lines.join,
          stderr: stderr_lines.join,
          exit_status:
        }
      end
    end

    # Return the config object associated to this instance
    #
    # @return [Config] The config instance used by this Cli instance
    def config
      @config ||= @config_dir.nil? ? Config.global : Config.open(@config_dir)
    end

    # Get all child PIDs recursively for a given parent PID
    #
    # @param parent_pid [Integer] Parent process ID
    # @return [Array<Integer>] All child and grandchild PIDs recursively
    def get_child_pids_recursive(parent_pid)
      child_pids = []
      begin
        Sys::ProcTable.ps.each do |process|
          next unless process.ppid == parent_pid

          child_pids << process.pid
          child_pids.concat(get_child_pids_recursive(process.pid))
        end
      rescue StandardError
        # Gracefully handle errors if processes disappear while enumerating
      end
      child_pids
    end
  end
end
