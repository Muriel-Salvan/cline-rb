describe Cline::Logs, '#save' do
  it 'persists modified logs to the cline.log file' do
    with_logs(
      lines: [
        { level: 30, msg: 'First log' },
        { level: 40, msg: 'Second log' }
      ]
    ) do |logs|
      logs << { level: 50, msg: 'Third log' }
      logs.save
      expect(File.read(logs.file)).to eq <<~LOGS
        {"level":30,"msg":"First log"}
        {"level":40,"msg":"Second log"}
        {"level":50,"msg":"Third log"}
      LOGS
    end
  end

  it 'persists mixed JSON and non-JSON logs to the cline.log file' do
    with_logs(
      lines: [
        { msg: 'First JSON log' },
        'Plain string entry',
        { msg: 'Second JSON log' }
      ]
    ) do |logs|
      logs << 'Another plain string'
      logs.save
      expect(File.read(logs.file)).to eq <<~LOGS
        {"msg":"First JSON log"}
        Plain string entry
        {"msg":"Second JSON log"}
        Another plain string
      LOGS
    end
  end

  it 'persists a newly instantiated logs file' do
    with_logs(lines: nil) do |logs|
      logs << { msg: 'New log entry' }
      logs.save
      expect(File.read(logs.file)).to eq <<~LOGS
        {"msg":"New log entry"}
      LOGS
    end
  end
end
