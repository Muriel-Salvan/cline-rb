describe Cline::Config, '.local' do
  around do |example|
    # Backup original value as it is a global cache
    original_local = described_class.instance_variable_get(:@local)
    begin
      # Clear cache
      described_class.remove_instance_variable(:@local) if described_class.instance_variable_defined?(:@local)
      with_temp_dir do |tmp_dir|
        tmp_dir = tmp_dir.gsub('\\', '/')
        # Create .cline directory structure
        cline_dir = File.join(tmp_dir, '.cline')
        FileUtils.mkdir_p(cline_dir)
        setup_config_dir(cline_dir, global_settings: { cline_web_tools_enabled: true })

        # Change to temporary directory for the test
        Dir.chdir(tmp_dir) do
          example.run
        end
      end
    ensure
      described_class.instance_variable_set(:@local, original_local)
    end
  end

  it 'loads local config from current working directory .cline' do
    expect(described_class.local.global_settings.cline_web_tools_enabled).to be true
  end
end
