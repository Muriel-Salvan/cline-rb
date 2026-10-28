describe Cline::Cli, '#task' do
  context 'when Cline exits normally' do
    it 'returns the last session message in the result hash' do
      result = cli_task(
        stub: {
          log: {},
          session: {
            messages: [
              { ts: 100, content: [{ text: 'First message' }] },
              { ts: 101, content: [{ text: 'Second message' }] },
              { ts: 102, content: [{ text: 'Third message' }] }
            ]
          }
        }
      )
      expect(result[:message]).not_to be_nil
      expect(result[:message].ts).to eq 102
      expect(result[:message].content.first.text).to eq 'Third message'
    end

    it 'returns the last session message of the assistant in the result hash' do
      result = cli_task(
        stub: {
          log: {},
          session: {
            messages: [
              { ts: 100, content: [{ text: 'Assistant message #1' }] },
              { ts: 101, role: 'user', content: [{ text: 'User message #1' }] },
              { ts: 102, content: [{ text: 'Assistant message #2' }] },
              { ts: 103, role: 'orchestrator', content: [{ text: 'Orchestrator message #1' }] },
              { ts: 104, role: 'user', content: [{ text: 'User message #2' }] }
            ]
          }
        }
      )
      expect(result[:message]).not_to be_nil
      expect(result[:message].ts).to eq 102
      expect(result[:message].content.first.text).to eq 'Assistant message #2'
    end

    it 'does not include message in the result when no session log was encountered' do
      expect(cli_task[:message]).to be_nil
    end

    it 'does not include message in the result when no session was created' do
      expect(cli_task(stub: { log: {} })[:message]).to be_nil
    end

    it 'does not include message in the result when the session has no messages' do
      expect(cli_task(stub: { log: {}, session: { messages: nil } })[:message]).to be_nil
    end

    it 'does not include message in the result when the session has empty messages' do
      expect(cli_task(stub: { log: {}, session: { messages: [] } })[:message]).to be_nil
    end

    it 'returns the session status in the result hash' do
      result = cli_task(
        stub: {
          log: {},
          session: {
            status: 'completed'
          }
        }
      )
      expect(result[:status]).to eq 'completed'
    end

    it 'returns the last error log in the result hash in case of a failed run' do
      result = cli_task(
        stub: {
          log: { level: 40, severity: 'error', msg: 'There is an error' },
          session: {
            status: 'failed'
          }
        }
      )
      expect(result[:error].severity).to eq 'error'
      expect(result[:error].msg).to eq 'There is an error'
      expect(result[:error].level).to eq 40
    end

    it 'does not return any error in the result hash in case of a completed run' do
      result = cli_task(
        stub: {
          log: { level: 50, severity: 'error', msg: 'There is an error' },
          session: {
            status: 'completed'
          }
        }
      )
      expect(result[:error]).to be_nil
    end

    it 'returns the last error log in the result hash in case of a cancelled run' do
      result = cli_task(
        stub: {
          log: { level: 40, severity: 'warn', msg: 'There is a warning' },
          session: {
            status: 'cancelled'
          }
        }
      )
      expect(result[:error]).not_to be_nil
      expect(result[:error].severity).to eq 'warn'
      expect(result[:error].msg).to eq 'There is a warning'
      expect(result[:error].level).to eq 40
      expect(result[:status]).to eq 'cancelled'
    end

    it 'does not return any error in the result hash in case of a failed run with no error log level' do
      result = cli_task(
        stub: {
          log: { level: 30, severity: 'info', msg: 'There is an info' },
          session: {
            status: 'failed'
          }
        }
      )
      expect(result[:error]).to be_nil
    end

    it 'does not return any error in the result hash in case of a cancelled run with no error log level' do
      result = cli_task(
        stub: {
          log: { level: 30, severity: 'info', msg: 'There is an info' },
          session: {
            status: 'cancelled'
          }
        }
      )
      expect(result[:error]).to be_nil
    end

    it 'returns the last error log from disk (not the stale in-memory cache) when the log file is updated after the session ID is discovered' do
      result = cli_task(
        stub: [
          # First log entry (level 40): startup fallback. The monitor discovers the
          # session ID from this entry (ulid present by default) and stops, freezing
          # the in-memory cache with this as the newest error log.
          {
            log: { level: 40, severity: 'error', msg: 'First error/warning message' },
            session: { status: 'failed' }
          },
          # Wait for the monitor to detect the first log entry, discover the session
          # ID, and stop monitoring — freezing @logs_lines in memory.
          { sleep: 2.0 },
          # Second log entry (level 40): the actual abort error. Written to disk
          # after the monitor stopped, so it is NOT in the in-memory cache.
          { log: { level: 40, severity: 'error', msg: 'Final error message' } }
        ]
      )
      expect(result[:error]).not_to be_nil
      expect(result[:error].msg).to eq 'Final error message'
      expect(result[:error].severity).to eq 'error'
      expect(result[:error].level).to eq 40
    end
  end
end
