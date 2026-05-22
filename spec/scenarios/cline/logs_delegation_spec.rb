describe Cline::Logs do
  describe 'delegated methods from the logs object' do
    it 'delegates enumerating methods to the internal logs' do
      with_logs(
        lines: [
          { time: '2026-01-01T00:00:00.000Z', msg: 'First' },
          { time: '2026-01-01T00:00:01.000Z', msg: 'Second' },
          { time: '2026-01-01T00:00:02.000Z', msg: 'Third' }
        ]
      ) do |logs|
        expect(logs.size).to eq 3
        expect(logs.first.msg).to eq 'First'
        expect(logs.last.msg).to eq 'Third'
        expect(logs[1].msg).to eq 'Second'
        expect(logs.empty?).to be false
      end
    end
  end
end
