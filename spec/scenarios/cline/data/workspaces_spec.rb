describe Cline::Data, '#workspaces' do
  it 'returns Workspaces instance even when no workspaces directory exists in data directory' do
    with_data_dir(workspaces: nil) do |data_dir|
      workspaces = described_class.from_dir(data_dir).workspaces
      expect(workspaces.size).to eq 0
    end
  end

  it 'returns Workspaces instance with correct count when workspaces exist' do
    with_data_dir(
      workspaces: {
        'workspace-1' => {},
        'workspace-2' => {},
        'workspace-3' => {}
      }
    ) do |data_dir|
      workspaces = described_class.from_dir(data_dir).workspaces
      expect(workspaces.size).to eq 3
      expect(workspaces['workspace-1']).not_to be_nil
      expect(workspaces['workspace-2']).not_to be_nil
      expect(workspaces['workspace-3']).not_to be_nil
      expect(workspaces['workspace-4']).to be_nil
    end
  end

  describe '#settings' do
    # Provide a test workspace
    #
    # @param name [String] The workspace name
    # @param settings [Hash, nil] The workspace settings, or nil if none
    # @yield [workspace] Block called with the test workspace ready
    # @yieldparam [Cline::Workspace] The test workspace
    def with_workspace(name: 'test-workspace', settings: nil)
      with_data_dir(
        workspaces: {
          name => {
            settings:
          }
        }
      ) do |data_dir|
        yield described_class.from_dir(data_dir).workspaces[name]
      end
    end

    it 'returns nil when no workspaceState.json file exists in workspace directory' do
      with_workspace(settings: nil) do |workspace|
        expect(workspace.settings).to be_nil
      end
    end

    it 'ignores extra unknown parameters from workspaceState.json file' do
      with_workspace(
        settings: {
          local_skills_toggles: { skill1: true, skill2: false },
          local_cline_rules_toggles: { rule1: true },
          this_is_an_unknown_parameter: 'should be ignored',
          another_extra_field: 12_345
        }
      ) do |workspace|
        settings = workspace.settings
        # Verify valid attributes are still correctly loaded
        expect(settings.local_skills_toggles.to_h).to eq({ 'skill1' => true, 'skill2' => false })
        expect(settings.local_cline_rules_toggles.to_h).to eq({ 'rule1' => true })
        # Verify unknown parameters are not present on the object
        expect(settings).not_to respond_to(:this_is_an_unknown_parameter)
        expect(settings).not_to respond_to(:another_extra_field)
      end
    end

    it 'loads all settings' do
      with_workspace(
        settings: {
          local_skills_toggles: { skill1: true, skill2: false, skill3: true },
          local_cline_rules_toggles: { rule1: true, rule2: false },
          local_agents_rules_toggles: { agent1: false, agent2: true },
          workflow_toggles: { flow1: true, flow2: true, flow3: false },
          local_windsurf_rules_toggles: { windsurf1: false },
          local_cursor_rules_toggles: { cursor1: true, cursor2: true },
          __vscode_migration_version: 7
        }
      ) do |workspace|
        settings = workspace.settings
        expect(settings.local_skills_toggles.to_h).to eq({ 'skill1' => true, 'skill2' => false, 'skill3' => true })
        expect(settings.local_skills_toggles['skill1']).to be true
        expect(settings.local_skills_toggles['skill2']).to be false
        expect(settings.local_skills_toggles['skill3']).to be true
        expect(settings.local_cline_rules_toggles.to_h).to eq({ 'rule1' => true, 'rule2' => false })
        expect(settings.local_agents_rules_toggles.to_h).to eq({ 'agent1' => false, 'agent2' => true })
        expect(settings.workflow_toggles.to_h).to eq({ 'flow1' => true, 'flow2' => true, 'flow3' => false })
        expect(settings.local_windsurf_rules_toggles.to_h).to eq({ 'windsurf1' => false })
        expect(settings.local_cursor_rules_toggles.to_h).to eq({ 'cursor1' => true, 'cursor2' => true })
        expect(settings.__vscode_migration_version).to eq 7
      end
    end

    describe '#==' do
      it 'returns true when 2 workspaces from different data directories have the same settings' do
        settings_hash = {
          local_skills_toggles: { skill1: true, skill2: false },
          local_cline_rules_toggles: { rule1: true }
        }

        with_workspace(settings: settings_hash) do |workspace1|
          with_workspace(name: 'test-workspace-2', settings: settings_hash) do |workspace2|
            # Workspaces are from different data directories but have identical settings
            expect(workspace1).not_to equal(workspace2) # Different instances
            expect(workspace1).to eq(workspace2)
            expect(workspace1.settings).not_to equal(workspace2.settings)
            expect(workspace1.settings).to eq(workspace2.settings)
          end
        end
      end

      it 'returns false when 2 workspaces have different setting attributes' do
        with_workspace(settings: { local_skills_toggles: { skill1: true } }) do |workspace1|
          with_workspace(settings: { local_skills_toggles: { skill1: false } }) do |workspace2|
            expect(workspace1).not_to eq(workspace2)
            expect(workspace1.settings).not_to eq(workspace2.settings)
          end
        end
      end

      it 'returns false when 2 workspaces have different setting attributes that are unknown' do
        with_workspace(settings: { unknown_attribute: 1 }) do |workspace1|
          with_workspace(settings: { unknown_attribute: 2 }) do |workspace2|
            expect(workspace1).not_to eq(workspace2)
            expect(workspace1.settings).not_to eq(workspace2.settings)
          end
        end
      end
    end
  end
end
