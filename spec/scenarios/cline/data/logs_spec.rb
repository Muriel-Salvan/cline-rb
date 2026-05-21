describe Cline::Data, '#logs' do
  it 'returns no logs when no log file exists in data directory' do
    with_data do |data|
      expect(data.logs).to be_nil
    end
  end

  it 'initializes logs when data is initialized with create option' do
    with_data(create: true) do |data|
      expect(data.logs).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'logs', 'cline.log'))).to be true
    end
  end

  it 'initializes logs when create option is given' do
    with_data do |data|
      expect(data.logs(create: true)).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'logs', 'cline.log'))).to be true
    end
  end

  it 'returns Logs instance with correct content when log file exists' do
    with_data(
      logs: [
        { msg: 'First log' },
        { msg: 'Second log' }
      ]
    ) do |data|
      logs = data.logs
      expect(logs.size).to eq 2
      expect(logs[0].msg).to eq 'First log'
      expect(logs[1].msg).to eq 'Second log'
    end
  end

  # TODO: Add 1 test case validating that all attributes of logs are correctly read
  # TODO: Add 1 test case validating that unknown attributes from logs are ignored and not present in the Log object
  # TODO: Add 1 test case validating that non-JSON log entries (use direct strings in the logs data_kwargs) are handled properly
  # TODO: Add test cases for save in logs/save_spec.rb
end
