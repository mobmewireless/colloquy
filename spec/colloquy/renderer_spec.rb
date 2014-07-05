require_relative '../spec_helper'

require 'fileutils'
require 'em-synchrony/mysql2'

RSpec::Matchers.define :be_a_memory_store_with do |flow, key, value|
  match do |actual|
    expect(actual[flow][key]).to eq value
  end
end

describe Colloquy::Renderer do

  RENDERER_PATH_ROOT = Pathname.new(File.dirname(__FILE__)).join('..', '..', 'examples')

  subject(:renderer) { Colloquy::Renderer.new }
  let(:example_renderer) { Colloquy::Renderer.new(path_root: RENDERER_PATH_ROOT) }
  let(:flow_pool) { Colloquy::Renderer::FlowPool }

  before(:each) do
    em_mysql_mock = double(Mysql2::EM::Client)

    allow(Colloquy::Helpers::MySQL::MySQLProxy.instance).to receive(:mysql_connection).and_return(em_mysql_mock)
  end

  context 'on asked to prepare' do
    before(:each) do
      allow(renderer).to receive(:configuration_valid?).and_return(true)
      allow(renderer).to receive(:configure)
    end

    it 'should configure itself if configuration is valid' do
      expect(renderer).to receive(:configuration_valid?)
      expect(renderer).to receive(:configure)

      renderer.prepare!
    end

    describe '#configuration_valid?' do
      it 'throws an error if the root path is invalid' do
        renderer_invalid = Colloquy::Renderer.new(path_root: '/abracadabra')
        expect { renderer_invalid.prepare! }.to raise_error Colloquy::ConfigurationFolderNotFound
      end

      it "throws an error if it can't find a valid config directory in the root path" do
        renderer_invalid = Colloquy::Renderer.new(path_root: '/tmp')
        expect { renderer_invalid.prepare! }.to raise_error Colloquy::ConfigurationFolderNotFound
      end

      it 'throws an error if flow yamls for configuration does not exist' do
        begin
          test_path = Pathname.new('/tmp/ussd_renderer_test/config')
          FileUtils.mkdir_p(test_path)
          renderer_without_flow_yaml = Colloquy::Renderer.new(path_root: test_path.join('..'))

          expect { renderer_without_flow_yaml.prepare! }.to raise_error Colloquy::FlowConfigurationNotFound
        ensure
          FileUtils.rm_rf(test_path.join('..'))
        end
      end

      it 'throws an error if logger yaml for configuration does not exist' do
        begin
          test_path = Pathname.new('/tmp/ussd_renderer_test/config')
          FileUtils.mkdir_p(test_path)
          FileUtils.touch(test_path.join('flows.yaml'))
          FileUtils.touch(test_path.join('messages.yaml'))

          renderer_without_logger_yaml = Colloquy::Renderer.new(path_root: test_path.join('..'))

          expect { renderer_without_logger_yaml.prepare! }.to raise_error Colloquy::LoggerConfigurationNotFound
        ensure
          FileUtils.rm_rf(test_path.join('..'))
        end
      end

      it 'throws an error if message yaml for configuration does not exist' do
        begin
          test_path = Pathname.new('/tmp/ussd_renderer_test/config')
          FileUtils.mkdir_p(test_path)
          FileUtils.touch(test_path.join('flows.yaml'))
          FileUtils.touch(test_path.join('logger.yaml'))

          renderer_without_logger_yaml = Colloquy::Renderer.new(path_root: test_path.join('..'))

          expect { renderer_without_logger_yaml.prepare! }.to raise_error Colloquy::MessagesConfigurationNotFound
        ensure
          FileUtils.rm_rf(test_path.join('..'))
        end
      end

      it 'throws appropriate errors on invalid YAML inside flows.yaml or logger.yaml'

      it "throws error if flows.yaml doesn't have a flows array as the parent node"

      it "throws an error if logger.yaml doesn't have log level and path to log to"

      it "throws an error if logger.yaml doesn't have valid options for log_level"

      it 'throws an error if flow messages.yaml is empty'
    end

    context 'from configuration' do
      it 'loads log file path and default verbosity and creates a logger' do
        example_renderer.prepare!

        expect(example_renderer.instance_variable_get(:@logger).class).to eq(Colloquy::Logger)
      end

      it 'loads relative paths from flows.yaml into Ruby load path' do
        expect($LOAD_PATH).to include Pathname.new(RENDERER_PATH_ROOT).join('flows').realpath.to_s
      end

      it 'loads absolute paths from flows.yaml into Ruby load path' do
        expect($LOAD_PATH).to include Pathname.new('/tmp').realpath.to_s
      end

      it 'loads and caches the flows and its messages' do
        calculator_flow_double = double(CalculatorFlow, messages: nil)

        allow(CalculatorFlow).to receive(:new).and_return(calculator_flow_double)
        expect(calculator_flow_double).to receive(:messages=).with(hash_including(add: 'Add', subtract: 'Subtract'))

        example_renderer.prepare!

        expect(example_renderer.instance_variable_get(:@flows)).to include(calculator: calculator_flow_double)
      end

      it 'loads messages having deep hashes correctly' do
        active_record_flow_double = double(ActiveRecordFlow, messages: nil)

        allow(ActiveRecordFlow).to receive(:new).and_return(active_record_flow_double)
        expect(active_record_flow_double).to receive(:messages=) do |args| #.with(hash_including(activation: { success: 'Thank you! %{count} mobile numbers in total!' }))
          expect(args).to include('activation' => { 'success' => 'Thank you! %{count} mobile numbers in total!' })
        end
        example_renderer.prepare!
      end

      it 'loads messages from flow-wide messages.yaml' do
        example_renderer.prepare!

        expect(example_renderer.instance_variable_get(:@options)[:messages]).to include(more: 'More')
      end

      it "loads messages from flow-wide messages.yaml into each flow's messages" do
        calculator_flow_double = double(CalculatorFlow, messages: nil)

        allow(CalculatorFlow).to receive(:new).and_return(calculator_flow_double)
        expect(calculator_flow_double).to receive(:messages=).with(hash_including(more: 'More'))

        example_renderer.prepare!
      end

      it "overrides messages in flow-wide messages.yaml with the same messages having the same keys in flow's messages.yaml" do
        database_flow_double = double(DatabaseFlow, messages: nil)

        allow(DatabaseFlow).to receive(:new).and_return(database_flow_double)
        expect(database_flow_double).to receive(:messages=).with(hash_including(more: 'Next Page'))

        example_renderer.prepare!
      end

      it 'sets the maximum message length from flows.yaml' do
        example_renderer.prepare!

        expect(example_renderer.instance_variable_get(:@options)[:flows]).to include(maximum_message_length: 160)
      end
    end

    it 'initialises session and state stores' do
      example_renderer.prepare!

      expect(example_renderer.instance_variable_get(:@session)[:calculator].class).to eq Colloquy::SessionStore::Memory
      expect(example_renderer.instance_variable_get(:@state)[:calculator].class).to eq Colloquy::SessionStore::Memory
    end

    it 'loads the flow pool' do
      example_renderer.prepare!
      flow_pool = Colloquy::Renderer::FlowPool.flow_pool

      expect(flow_pool.keys.count).to eq 12
      expect(flow_pool.keys).to include(:calculator, :special_redis)
      expect(flow_pool[:calculator].first.class).to be(CalculatorFlow)
      expect(flow_pool[:special_redis].first.class).to be(RedisFlow)
    end
  end

  describe '#apply' do
    before(:each) do
      example_renderer.prepare!
    end

    it 'sets session and state to the stored flow session and state' do
      expect(example_renderer.apply(:calculator, 99, 1000, nil)).to eq("1. Add\n2. Subtract\n3. Back")
      expect(example_renderer.apply(:calculator, 99, 1000, 1)).to eq('Enter the first number:')
    end

    it 'handles flows which are strings rather than symbols' do
      expect(example_renderer.apply('calculator', 99, 1000, nil)).to eq("1. Add\n2. Subtract\n3. Back")
      expect(example_renderer.apply('calculator', 99, 1000, 1)).to eq('Enter the first number:')
    end

    it 'passes the logger on to the flow' do
      expect(example_renderer.instance_variable_get(:@flows)[:calculator].logger).to be(example_renderer.instance_variable_get(:@logger))
    end

    it 'passes along the flow name, mobile number, session_id and input to the flow in headers' do
      expect_any_instance_of(CalculatorFlow).to receive(:headers=).with(hash_including(flow_name: :calculator, msisdn: 99, session_id: 1000, input: 1, page: 1))
      example_renderer.apply(:calculator, 99, 1000, 1)
    end

    it 'handles different sessions & state based on msisdn simultaneously' do
      expect(example_renderer.apply(:calculator, 99, 1000, nil)).to eq("1. Add\n2. Subtract\n3. Back")
      expect(example_renderer.apply(:calculator, 98, 1000, nil)).to eq("1. Add\n2. Subtract\n3. Back")
      expect(example_renderer.apply(:calculator, 99, 1000, 1)).to eq('Enter the first number:')
      expect(example_renderer.apply(:calculator, 97, 1000, nil)).to eq("1. Add\n2. Subtract\n3. Back")
      expect(example_renderer.apply(:calculator, 99, 1000, 2)).to eq('Enter the second number:')
      expect(example_renderer.apply(:calculator, 97, 1000, 1)).to eq('Enter the first number:')
    end

    it 'can take in extra metadata which is available in the flow' do
      expect(example_renderer.apply(:metadata, 99, 1000, nil)).to eq('I love ')
      expect(example_renderer.apply(:metadata, 98, 1000, nil,  love: 'Apple')).to eq('I love Apple')
    end

    it 'pops the correct flow from the flow pool and adds it back' do
      expect(flow_pool).to receive(:pop_flow).with(:special_redis).and_return(RedisFlow.new(:special_redis))
      expect(flow_pool).to receive(:add_flow).with(:special_redis, instance_of(RedisFlow))
      expect(example_renderer.apply(:special_redis, 99, 1000, nil)).to eq("1. activate\n2. cancel\n3. back")

      expect(flow_pool).to receive(:pop_flow).with(:special_redis).and_return(RedisFlow.new(:special_redis))
      expect(flow_pool).to receive(:add_flow).with(:special_redis, instance_of(RedisFlow))
      expect(example_renderer.apply(:special_redis, 99, 1000, 1)).to eq('activation_success')
    end

    context 'switching between flows' do
      it 'switches between flows' do
        example_renderer.apply(:art_of_war, 99, 1000, nil)
        expect(example_renderer.apply(:art_of_war, 99, 1000, 1)).to eq("1. Add\n2. Subtract\n3. Back")
        expect(example_renderer.apply(:art_of_war, 99, 1000, 1)).to eq('Enter the first number:')
        expect(example_renderer.apply(:art_of_war, 99, 1000, 1)).to eq('Enter the second number:')
        expect(example_renderer.apply(:art_of_war, 99, 1000, 1)).to eq('The result is: 2')
      end

      it 'raises error when the switch flow is not present' do
        example_renderer.apply(:art_of_war, 99, 1000, nil)
        expect(example_renderer.apply(:art_of_war, 99, 1000, 5)).to eq("We're facing technical difficulties at this time. Please try again later!")
      end

      it 'can switch back to an original flow' do
        example_renderer.apply(:art_of_war, 99, 1000, nil)

        expect(example_renderer.apply(:art_of_war, 99, 1000, 1)).to eq("1. Add\n2. Subtract\n3. Back")
        expect(example_renderer.apply(:art_of_war, 99, 1000, 3)).to eq("1. Switch to Calculator flow\n2. special_redis\n3. estimates\n4. waging_war\n5. offensive_strategy\n6. dispositions\n7. energy\n8. weaknesses_and_strengths\n9. More")
      end

      it 'should store session variables even when switching across flows' do
        example_renderer.apply(:crossover, 99, 1000, 1)
        expect(example_renderer.instance_variable_get(:@session)).to be_a_memory_store_with(:crossover, '99-1000', calculator_type: :scientific)
      end

      it 'can switch to and fro many times' do
        example_renderer.apply(:art_of_war, 99, 1000, nil)

        expect(example_renderer.apply(:art_of_war, 99, 1000, 1)).to eq("1. Add\n2. Subtract\n3. Back")
        expect(example_renderer.apply(:art_of_war, 99, 1000, 3)).to eq("1. Switch to Calculator flow\n2. special_redis\n3. estimates\n4. waging_war\n5. offensive_strategy\n6. dispositions\n7. energy\n8. weaknesses_and_strengths\n9. More")
        expect(example_renderer.apply(:art_of_war, 99, 1000, 1)).to eq("1. Add\n2. Subtract\n3. Back")
        expect(example_renderer.apply(:art_of_war, 99, 1000, 3)).to eq("1. Switch to Calculator flow\n2. special_redis\n3. estimates\n4. waging_war\n5. offensive_strategy\n6. dispositions\n7. energy\n8. weaknesses_and_strengths\n9. More")
      end

      it 'pops the correct flow from the flow pool and adds it back when switching to and fro flows' do
        expect(flow_pool).to receive(:pop_flow).with(:art_of_war).and_return(ArtOfWarFlow.new(:art_of_war))
        expect(flow_pool).to receive(:add_flow).with(:art_of_war, instance_of(ArtOfWarFlow))

        example_renderer.apply(:art_of_war, 99, 1000, nil)

        expect(flow_pool).to receive(:pop_flow).with(:art_of_war).and_return(ArtOfWarFlow.new(:art_of_war))
        expect(flow_pool).to receive(:add_flow).with(:art_of_war, instance_of(ArtOfWarFlow))
        expect(flow_pool).to receive(:pop_flow).with(:special_redis).and_return(RedisFlow.new(:special_redis))
        expect(flow_pool).to receive(:add_flow).with(:special_redis, instance_of(RedisFlow))

        example_renderer.apply(:art_of_war, 99, 1000, 2)

        expect(flow_pool).to receive(:pop_flow).with(:special_redis).and_return(RedisFlow.new(:special_redis))
        expect(flow_pool).to receive(:add_flow).with(:special_redis, instance_of(RedisFlow))
        expect(flow_pool).to receive(:pop_flow).with(:art_of_war).and_return(ArtOfWarFlow.new(:art_of_war))
        expect(flow_pool).to receive(:add_flow).with(:art_of_war, instance_of(ArtOfWarFlow))

        example_renderer.apply(:art_of_war, 99, 1000, 3)

        expect(flow_pool).to receive(:pop_flow).with(:art_of_war).and_return(ArtOfWarFlow.new(:art_of_war))
        expect(flow_pool).to receive(:add_flow).with(:art_of_war, instance_of(ArtOfWarFlow))
        expect(flow_pool).to receive(:pop_flow).with(:special_redis).and_return(RedisFlow.new(:special_redis))
        expect(flow_pool).to receive(:add_flow).with(:special_redis, instance_of(RedisFlow))

        example_renderer.apply(:art_of_war, 99, 1000, 2)

        expect(flow_pool).to receive(:pop_flow).with(:special_redis).and_return(RedisFlow.new(:special_redis))
        expect(flow_pool).to receive(:add_flow).with(:special_redis, instance_of(RedisFlow))
        expect(example_renderer.apply(:art_of_war, 99, 1000, 1)).to eq('activation_success')
      end
    end

    context 'messages should be correctly read from messages.yaml' do
      it 'should render messages from messages.yaml' do
        expect(example_renderer.instance_variable_get(:@flows)[:art_of_war].instance_variable_get(:@messages)).to include(calculator: 'Switch to Calculator flow')
        expect(example_renderer.apply(:art_of_war, 99, 1000)).to include('Switch to Calculator flow')
      end
    end
  end

  context 'reloading' do
    before(:each) do
      example_renderer.prepare!
    end

    it 'can reload messages' do
      messages = example_renderer.instance_variable_get(:@flows)[:calculator].messages
      example_renderer.instance_variable_get(:@flows)[:calculator].messages = nil

      example_renderer.reload_messages!

      expect(example_renderer.instance_variable_get(:@flows)[:calculator].messages).to eq(messages)
    end

    it 'can reloads all flows' do
      example_renderer.instance_variable_set(:@flows, [])

      example_renderer.reload_flows!

      expect(example_renderer.instance_variable_get(:@flows)).not_to eq([])
    end

    it 'can reload a particular flow' do
      example_renderer.instance_variable_set(:@flows, [])

      example_renderer.reload_flows!

      expect(example_renderer.instance_variable_get(:@flows)[:calculator]).not_to eq([])
    end
  end

  context 'prefixes and suffixes' do
    before(:each) do
      example_renderer.prepare!
    end

    it 'can be decided based on values in the header' do
      expect(example_renderer.apply(:prefix_menu, 99, 1000, nil)).to eq("Hello 1000\n1. 99\n2. Abracadabra\n3. Boyish\n4. Cow Female\n5. d\n6. e\n7. More\nYour world is my oyster! And there's nothing better than beer! Or a touch of lemonade.")
      expect(example_renderer.instance_variable_get(:@session)).to be_a_memory_store_with(:prefix_menu, '99-1000',  wonker: 'Page: 1')
      expect(example_renderer.apply(:prefix_menu, 99, 1000, 7)).to eq("Hello 1000\n1. f\n2. g\n3. h\n4. i\n5. j\n6. k\n7. l\n8. m\n9. n\n10. o\n11. p\n12. q\n13. r\n14. s\n15. t\n16. u\n17. v\n18. w\n19. x\n20. y\n21. z\n22. Previous")
      expect(example_renderer.instance_variable_get(:@session)).to be_a_memory_store_with(:prefix_menu, '99-1000',  wonker: 'Page: 2')
    end

    context 'and their menu keys' do
      it 'works in the simplest case' do
        example_renderer.apply(:prefix_menu, 99, 1000, nil)

        expect(example_renderer.apply(:prefix_menu, 99, 1000, 2)).to eq('Abracadabra')
      end

      it 'works on subsequent pages' do
        example_renderer.apply(:prefix_menu, 99, 1000, nil)
        example_renderer.apply(:prefix_menu, 99, 1000, 7)

        expect(example_renderer.apply(:prefix_menu, 99, 1000, 2)).to eq('g')
      end

      it 'works with multiple session ids at the same time' do
        example_renderer.apply(:prefix_menu, 99, 1000, nil)
        example_renderer.apply(:prefix_menu, 99, 1000, 7)

        expect(example_renderer.apply(:prefix_menu, 99, 1000, 2)).to eq('g')

        example_renderer.apply(:prefix_menu, 98, 1001, nil)
        example_renderer.apply(:prefix_menu, 98, 1001, 7)

        expect(example_renderer.apply(:prefix_menu, 98, 1001, 2)).to eq('g')
      end
    end
  end

  context 'menu pagination' do
    it 'paginates menu properly when a long menu prefix is provided' do
      example_renderer.prepare!

      expect(example_renderer.apply(:pagination, 995, 1000, nil)).to eq "Welcome to Some new application. Please choose from one of the packs below to get latest news from Some new application\n1. Pack 1\n2. Pack 2\n3. Pack 3\n4. More"
      expect(example_renderer.apply(:pagination, 995, 1000, 4)).to eq "1. Pack 4\n2. Pack 5\n3. Pack 6\n4. Pack 7\n5. Pack 8\n6. Pack 9\n7. Pack 10\n8. Previous"
    end
  end

  context 'session store' do
    it 'works even when a flow switch happens' do
      example_renderer.prepare!
      example_renderer.apply(:art_of_war, 995, 1000, nil)

      expect(example_renderer.instance_variable_get(:@session)).to be_a_memory_store_with(:art_of_war, '995-1000',  hello: 'yellow!')
      expect(example_renderer.apply(:art_of_war, 995, 1000, 1)).to eq "1. Add\n2. Subtract\n3. Back"
      expect(example_renderer.instance_variable_get(:@session)).to be_a_memory_store_with(:art_of_war, '995-1000',  hello: 'world')
    end

    it 'can flush older sessions'

    context '#apply' do
      it "throws an error when it can't find session or state"
    end

    context '#apply!' do
      it "resets state and session to default when it can't find either"
    end
  end
end
