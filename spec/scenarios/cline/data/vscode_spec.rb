describe Cline::Data, '.vscode' do
  around do |example|
    # Backup original value as it is a global cache
    original_vscode = described_class.instance_variable_get(:@vscode)
    begin
      # Clear cache
      described_class.remove_instance_variable(:@vscode) if described_class.instance_variable_defined?(:@vscode)
      with_temp_dir do |tmp_dir|
        @tmp_dir = tmp_dir.gsub('\\', '/')
        example.run
      end
    ensure
      described_class.instance_variable_set(:@vscode, original_vscode)
    end
  end

  # @return [String] The temporary directory that contains the vscode cline data dir
  attr_reader :tmp_dir

  before do
    allow(ENV).to receive(:[]).and_call_original
  end

  context 'when the host OS is mingw32' do
    around do |example|
      with_host_os('mingw32') do
        example.call
      end
    end

    it 'loads vscode data from a portable installation' do
      allow(ENV).to receive(:[]).with('VSCODE_PORTABLE').and_return(tmp_dir)
      FileUtils.mkdir_p(File.join(tmp_dir, 'user-data', 'User', 'globalStorage', 'saoudrizwan.claude-dev'))
      expect(described_class.vscode.dir).to eq "#{tmp_dir}/user-data/User/globalStorage/saoudrizwan.claude-dev"
    end

    it 'loads vscode data from a system installation' do
      allow(ENV).to receive(:[]).with('VSCODE_PORTABLE').and_return(nil)
      allow(ENV).to receive(:[]).with('APPDATA').and_return(tmp_dir)
      FileUtils.mkdir_p(File.join(tmp_dir, 'Code', 'User', 'globalStorage', 'saoudrizwan.claude-dev'))
      expect(described_class.vscode.dir).to eq "#{tmp_dir}/Code/User/globalStorage/saoudrizwan.claude-dev"
    end
  end

  context 'when the host OS is linux' do
    around do |example|
      with_host_os('linux') do
        example.call
      end
    end

    it 'loads vscode data from a Portable installation' do
      allow(ENV).to receive(:[]).with('VSCODE_PORTABLE').and_return(tmp_dir)
      FileUtils.mkdir_p(File.join(tmp_dir, 'user-data', 'User', 'globalStorage', 'saoudrizwan.claude-dev'))
      expect(described_class.vscode.dir).to eq "#{tmp_dir}/user-data/User/globalStorage/saoudrizwan.claude-dev"
    end

    it 'loads vscode data from XDG_CONFIG_HOME/Code' do
      allow(ENV).to receive(:[]).with('VSCODE_PORTABLE').and_return(nil)
      allow(Cline::Utils::Os).to receive(:user_app_data_dir).and_return("#{tmp_dir}/.config")
      FileUtils.mkdir_p(File.join(tmp_dir, '.config', 'Code', 'User', 'globalStorage', 'saoudrizwan.claude-dev'))
      expect(described_class.vscode.dir).to eq "#{tmp_dir}/.config/Code/User/globalStorage/saoudrizwan.claude-dev"
    end
  end
end
