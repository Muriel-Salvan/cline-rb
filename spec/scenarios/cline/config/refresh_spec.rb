require 'fileutils'

describe Cline::Config, '#refresh!' do
  it 'clears the cached skills so they are reloaded from disk' do
    with_config(skills: { 'original-skill' => {} }) do |config|
      # Load skills into cache
      original_skills = config.skills
      expect(original_skills.keys).to eq ['original-skill']

      # Add a new skill directly on disk
      new_skill_dir = File.join(config.dir, 'skills', 'added-skill')
      FileUtils.mkdir_p(new_skill_dir)
      File.write(File.join(new_skill_dir, 'SKILL.md'), '# Added skill')

      # Without refresh, the cached value is still returned
      expect(config.skills).to equal(original_skills)

      # Refresh and verify the new skill is now loaded
      config.refresh!
      reloaded_skills = config.skills
      expect(reloaded_skills.keys).to eq %w[added-skill original-skill]
    end
  end

  it 'clears the cached data so it is reloaded from disk' do
    with_config(global_state: { clineWebToolsEnabled: true }) do |config|
      # Load data into cache
      original_data = config.data
      expect(original_data.global_state.cline_web_tools_enabled).to be true

      # Modify data directly on disk
      data_dir = config.data.dir
      global_state_file = File.join(data_dir, 'globalState.json')
      File.write(global_state_file, JSON.generate(clineWebToolsEnabled: false))

      # Without refresh, the cached value is still returned
      expect(config.data).to equal(original_data)

      # Refresh and verify the new data is now loaded
      config.refresh!
      expect(config.data.global_state.cline_web_tools_enabled).to be false
    end
  end

  it 'handles nil skills gracefully when nothing is cached yet' do
    with_config(skills: nil) do |config|
      # skills is nil initially since no skills directory exists
      config.refresh!
      expect(config.skills).to be_nil
    end
  end

  it 'handles nil data gracefully when nothing is cached yet' do
    with_temp_dir do |config_dir|
      config = described_class.open(config_dir)
      # data is nil initially since no data directory exists
      config.refresh!
      expect(config.data).to be_nil
    end
  end
end
