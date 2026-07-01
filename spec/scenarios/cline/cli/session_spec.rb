describe Cline::Cli, '#session' do
  it 'is nil when no task has been started' do
    expect(described_class.new.session).to be_nil
  end

  it 'is set after running a task' do
    cli_task(stub: { log: {}, session: {} }) do |cli|
      expect(cli.session).not_to be_nil
      expect(cli.session.session_id).to eq 'test-session-id'
    end
  end

  it 'returns the session\'s messages after running a task' do
    cli_task(stub: { log: {}, session: { messages: [{ ts: 100, content: [{ text: 'Test message' }] }] } }) do |cli|
      user_message = cli.session.messages.first
      expect(user_message.role).to eq 'user'
      expect(user_message.content.first.text).to eq '<user_input mode="act">Test prompt</user_input>'
      assistant_message = cli.session.messages[1]
      expect(assistant_message.ts).to eq 100
      expect(assistant_message.content.first.text).to eq 'Test message'
    end
  end

  it 'is set correctly inside the on_message callback' do
    with_config do |config|
      mock_commands(
        ['--config', config.dir, 'Test prompt'] => {
          log: {},
          session: { messages: [{ ts: 100, content: [{ text: 'Test message' }] }] }
        }
      )
      captured_session = nil
      cli = described_class.new(config: config.dir)
      cli.task(
        'Test prompt',
        on_message: proc do |_message, _last, _previous|
          captured_session = cli.session
        end,
        monitoring_interval_secs: 0.1
      )
      expect(captured_session).not_to be_nil
      expect(captured_session).to eq(cli.session)
    end
  end

  describe 'Cline models used in session messages' do
    # Setup the VSCode portable installation data and mock the VSCODE_PORTABLE environment variable.
    #
    # @param cline_models [Hash{String => Hash}, nil] The cline_models to create in the VSCode data directory, or nil if none.
    #   Each key is a model ID, each value is a hash of model attributes (e.g. 'name', 'maxTokens', ...).
    # @param vscode_root [String] The root temporary directory to use as the VSCode portable installation path.
    def setup_vscode_models(cline_models, vscode_root)
      vscode_data_dir = File.join(vscode_root, 'user-data', 'User', 'globalStorage', 'saoudrizwan.claude-dev')
      FileUtils.mkdir_p(vscode_data_dir)
      setup_data_dir(vscode_data_dir, cline_models:)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('VSCODE_PORTABLE').and_return(vscode_root)
    end

    around do |example|
      # Backup and clear the Data.vscode cache
      original_vscode = Cline::Data.instance_variable_get(:@vscode)
      Cline::Data.remove_instance_variable(:@vscode) if Cline::Data.instance_variable_defined?(:@vscode)
      begin
        example.run
      ensure
        Cline::Data.instance_variable_set(:@vscode, original_vscode)
      end
    end

    # Get the message returned by the session after running a task in a config dir having some Cline models defined.
    #
    # @param cline_models [Hash{String => Hash}, nil] The Cline models to create, or nil if none
    # @return [SessionMessage] The returned session message
    def capture_session_message(cline_models: nil)
      result = nil
      with_config(cline_models:) do |config|
        mock_commands(
          ['--config', config.dir, 'Test prompt'] => {
            log: {},
            session: { messages: [{ ts: 100, content: [{ text: 'Test message' }] }] }
          }
        )
        cli = described_class.new(config: config.dir)
        cli.task('Test prompt')
        result = cli.session.messages.first
      end
      result
    end

    it 'uses Cline models from config data dir' do
      expect(
        capture_session_message(cline_models: { 'test/model-1' => { 'name' => 'Config Model' } }).cline_models['test/model-1'].name
      ).to eq 'Config Model'
    end

    it 'uses Cline models from VSCode when config data dir has no models' do
      with_temp_dir do |vscode_root|
        setup_vscode_models({ 'test/model-1' => { 'name' => 'VSCode Model' } }, vscode_root)
        expect(capture_session_message(cline_models: nil).cline_models['test/model-1'].name).to eq 'VSCode Model'
      end
    end

    it 'uses Cline models from VSCode when config data dir has no models even when CLI finishes before accessing VSCode data' do
      with_temp_dir do |vscode_root|
        setup_vscode_models({ 'test/model-1' => { 'name' => 'VSCode Model' } }, vscode_root)
        # Simulate a bit of lag while accessing the VSCode data folder
        allow(Cline::Data).to receive(:vscode).and_wrap_original do |original_vscode|
          sleep 0.5
          original_vscode.call
        end
        expect(capture_session_message(cline_models: nil).cline_models['test/model-1'].name).to eq 'VSCode Model'
      end
    end

    it 'uses Cline models from config data dir even when VSCode data also exists' do
      # TODO: Investigate non-deterministic failures on this test (especially on Linux):
      #      Failure/Error: result = cli.session.messages.first
      #
      #  NoMethodError:
      #    undefined method 'messages' for nil
      # ./spec/scenarios/cline/cli/session_spec.rb:86:in 'block in RSpec::ExampleGroups::ClineCliSession::ClineModelsUsedInSessionMessages#capture_session_message'
      # ./spec/cline_test/helpers/config.rb:21:in 'block in ClineTest::Helpers::Config#with_config'
      # ./spec/cline_test/helpers/temp_dir.rb:24:in 'ClineTest::Helpers::TempDir#with_temp_dir'
      # ./spec/cline_test/helpers/config.rb:19:in 'ClineTest::Helpers::Config#with_config'
      # ./spec/scenarios/cline/cli/session_spec.rb:77:in 'RSpec::ExampleGroups::ClineCliSession::ClineModelsUsedInSessionMessages#capture_session_message'
      # ./spec/scenarios/cline/cli/session_spec.rb:120:in 'block (4 levels) in <top (required)>'
      # ./spec/cline_test/helpers/temp_dir.rb:24:in 'ClineTest::Helpers::TempDir#with_temp_dir'
      # ./spec/scenarios/cline/cli/session_spec.rb:117:in 'block (3 levels) in <top (required)>'
      # ./spec/scenarios/cline/cli/session_spec.rb:65:in 'block (3 levels) in <top (required)>'
      # ./spec/spec_helper.rb:40:in 'block (2 levels) in <top (required)>'
      with_temp_dir do |vscode_root|
        setup_vscode_models({ 'test/model-1' => { 'name' => 'VSCode Model' } }, vscode_root)
        expect(
          capture_session_message(cline_models: { 'test/model-1' => { 'name' => 'Config Model' } }).cline_models['test/model-1'].name
        ).to eq 'Config Model'
      end
    end

    it 'does not return any Cline models when neither VSCode nor config dir have Cline models' do
      with_temp_dir do |vscode_root|
        setup_vscode_models(nil, vscode_root)
        expect(capture_session_message(cline_models: nil).cline_models).to be_nil
      end
    end

    it 'does not return any Cline models when VSCode dir does not exist and config dir has no Cline models' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('VSCODE_PORTABLE').and_return(nil)
      allow(Cline::Utils::Os).to receive(:user_app_data_dir).and_return '/unknown/vscode/directory'
      expect(capture_session_message(cline_models: nil).cline_models).to be_nil
    end
  end
end
