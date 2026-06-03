describe Cline::Config, '#==' do
  it 'returns true for identical configs' do
    skills = { 'test-skill' => {} }
    global_state = { clineWebToolsEnabled: true }
    with_config(skills:, global_state: global_state) do |config1|
      with_config(skills:, global_state: global_state) do |config2|
        expect(config1).not_to equal(config2)
        expect(config1).to eq(config2)
      end
    end
  end

  it 'returns false for different skills' do
    with_config(skills: { 'test-skill-1' => {} }) do |config1|
      with_config(skills: { 'test-skill-2' => {} }) do |config2|
        expect(config1).not_to eq(config2)
      end
    end
  end

  it 'returns false for different data' do
    skills = { 'test-skill' => {} }
    with_config(skills:, global_state: { clineWebToolsEnabled: true }) do |config1|
      with_config(global_state: { clineWebToolsEnabled: false }) do |config2|
        expect(config1).not_to eq(config2)
      end
    end
  end
end
