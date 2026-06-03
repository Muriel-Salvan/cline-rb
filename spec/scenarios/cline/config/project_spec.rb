describe Cline::Config, '.project' do
  around do |example|
    # Backup original value as it is a global cache
    original_project = described_class.instance_variable_get(:@project)
    begin
      # Clear cache
      described_class.remove_instance_variable(:@project) if described_class.instance_variable_defined?(:@project)
      with_temp_dir do |tmp_dir|
        tmp_dir = tmp_dir.gsub('\\', '/')
        # Create .cline directory structure
        cline_dir = File.join(tmp_dir, '.cline')
        FileUtils.mkdir_p(cline_dir)
        setup_config_dir(cline_dir, global_state: { clineWebToolsEnabled: true })

        # Change to temporary directory for the test
        Dir.chdir(tmp_dir) do
          example.run
        end
      end
    ensure
      described_class.instance_variable_set(:@project, original_project)
    end
  end

  it 'loads project config from current working directory .cline' do
    expect(described_class.project.global_state.cline_web_tools_enabled).to be true
  end
end
