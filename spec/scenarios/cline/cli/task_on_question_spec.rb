describe Cline::Cli, '#task' do
  describe 'the on_question callback' do
    it 'triggers on_question callback when a question is the last content item of the last message' do
      questions_received = []
      cli_task(
        stub: [
          { log: {} },
          {
            session: {
              messages: [
                { ts: 100, content: [{ type: 'text', text: 'Hello' }] },
                {
                  ts: 101,
                  content: [
                    {
                      type: 'tool_use',
                      name: 'ask_question',
                      input: { question: 'What is your name?', options: %w[Alice Bob] }
                    }
                  ]
                }
              ]
            }
          }
        ],
        on_question: proc do |question|
          questions_received << question
          'My answer'
        end
      )
      expect(questions_received.size).to eq 1
      expect(questions_received[0].question).to eq 'What is your name?'
      expect(questions_received[0].options.to_a).to eq %w[Alice Bob]
    end

    it 'does not trigger on_question callback when a question is not the last content item of the last message' do
      questions_received = []
      cli_task(
        stub: [
          { log: {} },
          {
            session: {
              messages: [
                {
                  ts: 100,
                  content: [
                    {
                      type: 'tool_use',
                      name: 'ask_question',
                      input: { question: 'What is your name?' }
                    },
                    { type: 'text', text: 'Extra text after the question' }
                  ]
                }
              ]
            }
          }
        ],
        on_question: proc do |_question|
          questions_received << true
          'My answer'
        end
      )
      expect(questions_received.empty?).to be true
    end

    it 'does not trigger on_question callback when a question is not part of the last message' do
      questions_received = []
      cli_task(
        stub: [
          { log: {} },
          {
            session: {
              messages: [
                {
                  ts: 100,
                  content: [
                    {
                      type: 'tool_use',
                      name: 'ask_question',
                      input: { question: 'What is your name?', options: %w[Alice Bob] }
                    }
                  ]
                },
                { ts: 101, content: [{ type: 'text', text: 'Follow up message' }] }
              ]
            }
          }
        ],
        on_question: proc do |_question|
          questions_received << true
          'My answer'
        end
      )
      expect(questions_received.empty?).to be true
    end

    it 'raises UnexpectedInteractiveSessionError when a question is asked without an on_question callback' do
      # Make sure thread exceptions are not output in stdout for this test, as it messes up tests output.
      original_report_on_exception = Thread.report_on_exception
      Thread.report_on_exception = false
      begin
        expect do
          cli_task(
            stub: [
              { log: {} },
              {
                session: {
                  messages: [
                    {
                      ts: 100,
                      content: [
                        {
                          type: 'tool_use',
                          name: 'ask_question',
                          input: { question: 'What is your name?' }
                        }
                      ]
                    }
                  ]
                }
              }
            ]
          )
        end.to raise_error(Cline::Cli::UnexpectedInteractiveSessionError, /Unexpected interactive session/)
      ensure
        Thread.report_on_exception = original_report_on_exception
      end
    end

    it 'uses the callback result as stdin' do
      result = cli_task(
        stub: [
          { log: {} },
          {
            session: {
              messages: [
                {
                  ts: 100,
                  content: [
                    {
                      type: 'tool_use',
                      name: 'ask_question',
                      input: { question: 'What is your name?' }
                    }
                  ]
                }
              ]
            }
          },
          {
            eval: <<~EO_RUBY
              puts "[STDIN RECEIVED]: \#{STDIN.gets.chomp}"
            EO_RUBY
          }
        ],
        on_question: proc do |_question|
          'My answer'
        end
      )
      expect(result[:stdout]).to include('[STDIN RECEIVED]: My answer')
    end
  end
end
