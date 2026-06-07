require 'human_number'
require 'pty_compat'
require 'sys/proctable'

# Load the HumanNumber locale files, as it does not do it automatically.
# TODO: Remove this when human_number will be fixed.
I18n.load_path += Dir[File.join(File.join(Gem::Specification.find_by_name('human_number').gem_dir, 'lib'), 'locales', '*.yml')]

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

    # Unexpected interactive session
    class UnexpectedInteractiveSessionError < RuntimeError
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
        # Run in plan mode
        plan: '--plan',
        # Output messages as JSON instead of styled text
        json: '--json',
        # Enable auto-approve all actions
        auto_approve: '--auto-approve',
        # Reasoning effort level between none|low|medium|high|xhigh
        thinking: '--thinking STRING',
        # Context compaction mode: agentic|basic|off
        compaction: '--compaction STRIG',
        # Open the terminal user interface (TUI) for interactive sessions
        tui: '--tui',
        # Session ID to resume, or nil for a new session
        id: '--id STRING',
        # Provider to use for the session
        provider: '--provider STRING',
        # API key to use for the session
        key: '--key STRING',
        # Model to use for the task
        model: '--model STRING',
        # Override the default system prompt
        system: '--system STRING',
        # Start a session that runs in the background hub
        zen: '--zen',
        # Number of maximum consecutive mistakes (retries) before exiting
        retries: '--retries INTEGER',
        # Optional timeout in seconds (applies only when provided)
        timeout: '--timeout INTEGER',
        # Run in Agent Client Protocol (ACP) mode for editor integration
        acp: '--acp',
        # Use isolated local state at this directory path
        data_dir: '--data-dir STRING',
        # Path to additional hooks directory for runtime hook injection
        hooks_dir: '--hooks-dir STRING',
        # Auto-create a detached git worktree under ~/.cline/worktrees/ and run the task there
        worktree: '--worktree',
        # Run the kanban app
        kanban: '--kanban'
      }
    }

    # @!group Public API

    # Constructor
    #
    # @param stdout_echo [Boolean] Do we echo stdout of Cline CLI?
    # @param kwargs [Hash{Symbol => Object}] Global options (see COMMANDS[:global])
    def initialize(stdout_echo: false, **kwargs)
      @global_options = parse_global_options(**kwargs)
      @stdout_echo = stdout_echo
      @config_dir = kwargs[:config]
      @cline_pid = nil
      # [Session] Session associated to this CLI run.
      # The session is discovered using:
      # 1. Cline logs appearing after executing CLI that contain a session ID.
      # 2. The session corresponding to this ID.
      @session = nil
    end

    # Authenticate the CLI
    #
    # @param kwargs [Hash{Symbol => Object}] Command options (see COMMANDS)
    # @return [Hash{Symbol => Object}] A set of return properties (see #run_cli)
    def auth(**kwargs)
      run_cli(command: 'auth', args: parse_auth_options(**kwargs))
    end

    # Start a task by sending a prompt
    #
    # @param prompt [String, nil] The prompt, or nil if none
    # @param on_message [#call, nil] Callback called for each new or updated message for the session of this prompt,
    #   or nil if none (see Session#monitor_message)
    # @param on_question [#call, nil] Callback called for each question that is asked by the assistant, or nil if none.
    #   This should be set if an interactive session is expected.
    #   If a question is asked without a callback to handle it, an UnexpectedInteractiveSessionError exceptioon will be raised.
    #   - Param question [SessionMessage::MessageContent::ToolUseInput] Question input with possible options
    #     (see SessionMessage::MessageContent::ToolUseInput).
    #   - Return [String] The answer that the user should provide to this assistant's question.
    # @param monitoring_interval_secs [Float] The monitoring interval in seconds
    # @param kwargs [Hash{Symbol => Object}] Command options (see COMMANDS)
    # @return [Hash{Symbol => Object}] A set of return properties (see #run_cli). Additionnally the following ones:
    #   - message [SessionMessage, nil] The last message of the session, or nil if none
    #   - status [String] The task status
    #   - error [Log, nil] In case of status "failed", get the last error log entry, or nil if no error.
    def task(prompt, on_message: nil, on_question: nil, monitoring_interval_secs: 1, **kwargs)
      result = {}
      start_time = Time.now
      session_monitor_thread = nil
      cli_running = true
      begin
        result = run_cli(
          args: parse_task_options(**kwargs) + (prompt ? [prompt.strip] : []),
          on_start: proc do |_reader, writer, _pid|
            session_monitor_thread = Thread.new do
              # Start monitoring logs to get the session ID.
              # Wait for logs to exist.
              sleep 0.1 while cli_running && !config.logs
              # Monitor logs to get the session ID
              session_id = nil
              config.logs&.monitor(
                on_log: proc do |log, _last|
                  session_id = log.properties.ulid if !session_id && log.is_a?(Log) && log.properties&.ulid
                end,
                from: start_time
              ) do
                sleep 0.1 while cli_running && !session_id
              end
              # If CLI has finished, session_id should be already discovered, unless the session could not be created.
              # If CLI has not finished yet, the we have the session ID discovered already.
              # So it means that if session_id is nil, there has been a problem (like core dump).
              if session_id
                log_debug "Found Cline session ID #{session_id}"
                # Wait for the CLI to create the session for real
                sleep 0.1 while cli_running && !config.sessions
                while cli_running && !config.sessions[session_id]
                  sleep 0.1
                  config.sessions.refresh!
                end
                # If CLI has finished, then the session should exist, unless there has been a problem (like file system issue).
                @session = config.sessions && config.sessions[session_id]
                # Now monitor the session messages for reporting and possible user callback
                # [Hash{Integer => Usage}] All usages, per timestamp, for logging purposes
                usages = {}
                @session&.monitor_messages(
                  on_message: proc do |message, last, previous_version|
                    log_debug do
                      usages[message.ts] = message.usage if message.usage
                      last_usage = usages.values.last
                      prefix = "[#{message.timestamp.strftime('%H:%M:%S')}]#{
                        unless last_usage.nil?
                          " (#{HumanNumber.currency(usages.values.map { |usage| usage.cost || 0.0 }.sum, currency_code: 'USD')}" \
                            " #{HumanNumber.human_number(last_usage.context_tokens, max_digits: 2)}" \
                            "/#{HumanNumber.human_number(last_usage.context_tokens_limit || 0, max_digits: 2)})"
                        end
                      } - "
                      "#{prefix}#{message.to_human(limit: 128 - prefix.size)}"
                    end
                    # Call the user callback if any
                    on_message&.call(message, last, previous_version)
                    # If the message is the last one and the agent has asked a question, call the corresponding callback
                    if last
                      last_content = message.content&.last
                      if last_content&.type == 'tool_use' && last_content.name == 'ask_question'
                        unless on_question
                          raise UnexpectedInteractiveSessionError,
                            "Unexpected interactive session with assistant asking question #{last_content.input&.question}"
                        end

                        writer.puts(on_question.call(last_content.input))
                      end
                    end
                  end,
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
        session_monitor_thread&.join
      end
      if @session
        result[:message] = @session.messages&.last
        result[:status] = @session.status
        result[:error] = config.logs.logs(from: start_time).reverse_each.find { |log| log.severity == 'error' } if @session.status == 'failed'
      end
      result
    end

    # @return [Integer, nil] The PID of the running Cline process, if any
    attr_reader :cline_pid

    # @return [Session, nil] The current or last session handled by the Cline process, if any
    attr_reader :session

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

    # @!group Internal

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
            [cli_option] + [cli_arg.nil? ? nil : value.to_s]
          end
        end.flatten(1).compact
      end
    end

    # Run a command on the Cline CLI
    #
    # @param command [Symbol, nil] The command to run, or nil if none
    # @param args [Array<String>] Command arguments
    # @param stdin_data [String, nil] Data to send to the standard input of the CLI, or nil if none
    # @param expected_exit_status [Integer, nil] Expected exit status, or nil for no expectation
    # @param on_start [#call, nil] Optional callback that is called when the process is started
    #   - Param reader [IO] The process reader descriptor (stdout and stderr).
    #   - Param writer [IO] The process writer descriptor (stdin).
    #   - Param pid [Integer] The process PID.
    # @param on_stdout [#call, nil] Optional callback that is called for every line output on stdout
    #   - Param line [String] The stdout line (including potential \n)
    # @return [Hash{Symbol => Object}] A set of return properties:
    #   - stdout [String] Full stdout
    #   - exit_status [Integer] Exit status
    def run_cli(command: nil, args: [], stdin_data: nil, expected_exit_status: 0, on_start: nil, on_stdout: nil)
      cmd = Utils::Os.cline_exe +
        (command ? [command] : []) +
        @global_options +
        args
      log_debug "Launch CLI `#{cmd}`..."
      @interrupted_on_purpose = false
      stdout_lines = []
      exit_status = nil
      PTY.spawn(*cmd) do |reader, writer, pid|
        @cline_pid = pid
        log_debug "Cline master process started with PID #{cline_pid}"
        writer.write(stdin_data) if stdin_data
        on_start&.call(reader, writer, pid)
        begin
          reader.each_line do |line|
            stdout_lines << line
            $stdout.write(line) if @stdout_echo
            on_stdout&.call(line)
          end
        rescue Errno::EIO => e
          # Child process finished
          log_debug "Cline master process (PID #{cline_pid}) got terminated: #{e.message}"
        end
        exit_status = PTY.last_status.exitstatus
        log_debug do
          "Cline master process (PID #{cline_pid}) exited with status: #{exit_status}#{' (interrupted on purpose)' if @interrupted_on_purpose}"
        end
        @cline_pid = nil
        unless @stdout_echo
          log_debug do
            <<~EO_DEBUG
              ===== Cline CLI output BEGIN...
              #{Utils::Logger.sanitize_pty_output(stdout_lines.join)}
              ===== Cline CLI output ...END
            EO_DEBUG
          end
        end
        if !@interrupted_on_purpose && !expected_exit_status.nil? && exit_status != expected_exit_status
          raise UnexpectedExitStatusError, "Cline master process `#{cmd}` exited with status #{exit_status} (expected #{expected_exit_status})"
        end

        {
          stdout: Utils::Logger.sanitize_pty_output(stdout_lines.join),
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
