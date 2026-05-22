describe Cline::Data, '#workspaces' do
  it 'returns no workspaces when no directory exists in data directory' do
    with_data(workspaces: nil) do |data|
      expect(data.workspaces).to be_nil
    end
  end

  it 'initializes workspaces when data is initialized with create option' do
    with_data(workspaces: nil, create: true) do |data|
      expect(data.workspaces).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'workspaces'))).to be true
    end
  end

  it 'initializes workspaces when create option is given' do
    with_data(workspaces: nil) do |data|
      expect(data.workspaces(create: true)).not_to be_nil
      expect(File.exist?(File.join(data.dir, 'workspaces'))).to be true
    end
  end

  it 'returns Workspaces instance with correct count when workspaces exist' do
    with_data(
      workspaces: {
        'workspace-1' => {},
        'workspace-2' => {},
        'workspace-3' => {}
      }
    ) do |data|
      workspaces = data.workspaces
      expect(workspaces.size).to eq 3
      expect(workspaces.keys).to contain_exactly('workspace-1', 'workspace-2', 'workspace-3')
      expect(workspaces['workspace-1']).not_to be_nil
      expect(workspaces['workspace-2']).not_to be_nil
      expect(workspaces['workspace-3']).not_to be_nil
      expect(workspaces['workspace-4']).to be_nil
    end
  end
end
