describe Cline::Cli, '#task' do
  context 'when Cline exits normally' do
    it 'returns the last task message in the result hash' do
      with_config_dir do |config_dir|
        mock_commands(
          "cline --config #{config_dir}" => {
            task: {
              messages: [
                { ts: 100, text: 'First message' },
                { ts: 101, text: 'Second message' },
                { ts: 102, text: 'Third message' }
              ]
            }
          }
        )
        result = described_class.new(config: config_dir).task('Test prompt')
        expect(result[:message]).not_to be_nil
        expect(result[:message].ts).to eq 102
        expect(result[:message].type).to eq 'say'
        expect(result[:message].say).to eq 'text'
        expect(result[:message].text).to eq 'Third message'
      end
    end

    it 'does not include message in the result when no task was created' do
      mock_commands(
        'cline' => {
          stdout: "some output without task_started\n"
        }
      )
      expect(described_class.new.task('Test prompt')[:message]).to be_nil
    end

    it 'returns nil message when the task has no messages' do
      with_config_dir do |config_dir|
        mock_commands("cline --config #{config_dir}" => { task: {} })
        expect(described_class.new(config: config_dir).task('Test prompt')[:message]).to be_nil
      end
    end

    it 'returns nil message when the task has empty messages' do
      with_config_dir do |config_dir|
        mock_commands("cline --config #{config_dir}" => { task: { messages: [] } })
        expect(described_class.new(config: config_dir).task('Test prompt')[:message]).to be_nil
      end
    end
  end

  context 'when Cline issues a completion message' do
    completion_messages = {
      'ask/followup' => { ts: 100, type: 'ask', ask: 'followup', text: '{"question":"Continue?","options":[]}' },
      'ask/new_task' => { ts: 100, type: 'ask', ask: 'new_task', text: 'New task to pursue' },
      'ask/plan_mode_respond' => { ts: 100, type: 'ask', ask: 'plan_mode_respond', text: '{"response":"Plan response"}' },
      'say/completion_result' => { ts: 100, type: 'say', say: 'completion_result', text: 'Task completed successfully' }
    }

    ClineTest::Helpers::Os.possible_oses.each do |host_os|
      context "when running on OS #{host_os}" do
        around do |example|
          with_host_os(host_os) do
            example.call
          end
        end

        context 'when the completion message is not the last one' do
          completion_messages.each do |name, message|
            it "does not return when #{name} is not the last message" do
              with_config_dir do |config_dir|
                mock_commands(
                  "cline --config #{config_dir}" => {
                    task: {
                      messages: [
                        [
                          message,
                          { ts: 101, text: 'Another message' }
                        ]
                      ]
                    }
                  }
                )
                cli = described_class.new(config: config_dir)
                spy_killing_pids
                expect(cli.task('Test prompt', monitoring_interval_secs: 0.1)[:message].ts).to eq 101
                expect(killed_pids).to be_empty
              end
            end
          end
        end

        context 'when the completion message is the last one' do
          completion_messages.each do |name, message|
            it "returns when #{name} is the last message and Cline exited properly" do
              with_config_dir do |config_dir|
                mock_commands("cline --config #{config_dir}" => { task: { messages: [message] } })
                cline_pid = nil
                cli = described_class.new(config: config_dir)
                spy_killing_pids(
                  on_kill: proc do
                    # Wait for the cline_pid to disappear
                    sleep 0.1 while Sys::ProcTable.ps(pid: cline_pid)
                  end
                )
                capture_pid_thread = Thread.new do
                  sleep 0.1 until cli.cline_pid
                  cline_pid = cli.cline_pid
                end
                begin
                  expect(cli.task('Test prompt', monitoring_interval_secs: 0.1)[:message].ts).to eq 100
                ensure
                  capture_pid_thread.join
                end
                expect(killed_pids).to include(cline_pid)
              end
            end

            it "returns when #{name} is the last message and Cline process is stuck" do
              with_config_dir do |config_dir|
                mock_commands("cline --config #{config_dir}" => { task: { messages: [message] }, running_time_secs: 60 })
                cli = described_class.new(config: config_dir)
                spy_killing_pids
                expect(cli.task('Test prompt', monitoring_interval_secs: 0.1)[:message].ts).to eq 100
                expect(killed_pids).not_to be_empty
              end
            end
          end
        end
      end
    end
  end
end
