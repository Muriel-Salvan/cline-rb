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
          log: { severity: 'error', msg: 'There is an error' },
          session: {
            status: 'failed'
          }
        }
      )
      expect(result[:error].severity).to eq 'error'
      expect(result[:error].msg).to eq 'There is an error'
    end

    it 'does not return any error in the result hash in case of a completed run' do
      result = cli_task(
        stub: {
          log: {},
          session: {
            status: 'completed'
          }
        }
      )
      expect(result[:error]).to be_nil
    end
  end
end
