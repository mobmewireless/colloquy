require_relative '../spec_helper'

describe Colloquy::FlowParser do
  FLOW_PARSER_MENU_MESSAGES = {
      a: 'Apple', b: 'Boy', c: 'Cat',
      d: 'Created by Shigeru Miyamoto, Donkey-Kong is a series of video games that features the adventures of a large ape.',
      e: 'Elephant', f: 'Fool', g: 'God',
      h: 'Hibiscus is a super plant! It is very red and blue and all.',
      i: 'Idiot', j: 'Joker',
      k: 'King Kong is super comedy',
      l: 'Love', m: 'Mother', n: 'Neat', o: 'Open',
      p: 'Princess', q: 'Queen', r: 'Reindeer', s: 'Socrates',
      t: 'Talktime', u: 'Umbrella', v: 'Victory', w: 'Wonderful',
      x: 'Xena', y: 'YoYo', z: 'Zero'
  }
  
  FLOW_PARSER_PROMPT_MESSAGES = {
    :a => "Apple", :b => "Boy", :c => "Cat", 
    :d => "Created by Shigeru Miyamoto, Donkey-Kong 
      is a series of video games that features the adventures of a large ape.
      Donkey-Kong is a series of video games that features the adventures of a large ape.
      Donkey-Kong is a series of video games that features the adventures of a large ape."
  }
  
  let(:calculator) do 
    class Calculator
      include Colloquy::FlowParser
    end.new
  end
  
  it 'stores a node collection' do
    expect(calculator.nodes).to eq []
  end
  
  it 'should have a session, messages and headers' do
    expect(calculator).to respond_to(:session)
    expect(calculator).to respond_to(:messages)
    expect(calculator).to respond_to(:headers)
  end
  
  context '#node_add' do
    before(:each) do
      calculator.node_add(:hello) { prompt 'Hello World' }
    end

    it 'creates a node' do
      expect(calculator.nodes.length).to eq 1
    end

    it 'creates node the supplied identifier and block' do
      expect(calculator.send(:node_by_id, :hello).identifier).to eq(:hello)
    end

    it 'throws an exception on duplicate identifier' do
      expect { calculator.node_add(:hello) { prompt 'Another Hello' } }.to raise_error(Colloquy::DuplicateNodeException)
    end
    
    it 'passses on the flow to the node created' do
      expect(calculator.nodes[0].instance_variable_get(:@flow)).to eq(calculator)
    end
  end
  
  describe 'session' do
    it 'maintains a session' do
      expect(calculator.session).to respond_to(:[])
    end
  
    it 'can read from and write to the session' do
      calculator.session[:hello] = :world

      expect(calculator.session[:hello]).to eq(:world)
    end
  end

  # @todo #state and #notify! are private methods. Are these tests needed?
  describe 'state' do
    it 'stores state, which is a triple of flow name, node name and flow state' do
      expect(calculator.send(:state)).not_to eq nil
      expect(calculator.send(:state)).to include :flow_name
      expect(calculator.send(:state)).to include :node
      expect(calculator.send(:state)).to include :flow_state
      
      expect(calculator.send(:state)[:flow_name]).to eq :calculator
    end
    
    it 'ensures that the initial state is the index node and the initial flow state is nil' do
      expect(calculator.send(:state)).to include(node: :index, flow_state: :init)
    end
  end
  
  describe '#notify!' do
    it 'takes a message string to notify' do
      expect(calculator.send(:notify!, 'Hello World!')).to eq('Hello World!')
    end
    
    it 'takes a symbol that is passed on to the messages hash to get back the message' do
      allow(calculator.messages).to receive(:[]).with(:hello_world).and_return('Hello World!')
      
      expect(calculator.send(:notify!, :hello_world)).to eq('Hello World!')
    end
  end
  
  describe '#apply' do
    it 'can take an input to manipulate the state' do
      expect(calculator).to respond_to :apply
    end
    
    context 'on start' do
      it 'throws an exception if the index node is not present' do
        expect { calculator.apply }.to raise_error Colloquy::IndexNodeNotFoundException
      end
    
      it 'calls the render function on the index node on start if present' do
        calculator.node_add(:index)
        allow(calculator.send(:node_by_id, :index)).to receive :render

        calculator.apply
      end
    end
    
    context 'simple notify flow' do
      before do
        calculator.node_add(:index) do
          request {
            notify 'Hello World'
          }
        end
      end
      
      it 'calls #notify on notify in the flow' do
        allow(calculator).to receive(:notify!).with('Hello World')
        
        calculator.apply
      end
    end
    
    context 'flow with an initial input' do
      before do
        calculator.node_add(:index) do
          request { |input|
            if input == '2'
              notify 'Hello World'
            else
              notify 'Grr!'
            end
          }
        end
      end
      
      it 'calls #notify on notify in the flow' do
        allow(calculator).to receive(:notify!).with('Hello World')

        calculator.apply(2)
      end
    end
    
    context 'switch flow' do
      before do
        calculator.node_add(:index) do
          request {
            switch :branch
          }
        end
        
        calculator.node_add(:branch)
      end
      
      it 'switches node and flow state on switch statements in the flow' do
        calculator.apply

        expect(calculator.send(:state)).to include(node: :branch, flow_state: :request)
      end
    end
    
    context 'switch flow to an unknown node' do
      before do
        calculator.node_add(:index) do
          request {
            switch :unknown
          }
        end
        
        calculator.node_add(:branch)
      end
      
      it 'raises an exception when a node is not found to switch to' do
        expect { calculator.apply }.to raise_error Colloquy::NodeNotFoundException
      end
    end
    
    context 'switch flow on input' do
      before do
        calculator.node_add(:index) do
          request {
            prompt 'Enter 1 to branch'
          }
          process { |input|
            case input
            when '1'
              switch :branch
            else
              notify 'Hello'
            end
          }
        end
          
        calculator.node_add(:branch)
      end
      
      it 'switches flow state when input is 1' do
        calculator.apply
        calculator.apply(1)
        
        expect(calculator.send(:state)).to include(node: :branch, flow_state: :request)
      end
      
      it "switches flow state when input is '1'" do
        calculator.apply
        calculator.apply('1')
        
        expect(calculator.send(:state)).to include(node: :branch, flow_state: :request)
      end
      
      it 'notifies when input is 2' do
        calculator.apply
        calculator.apply(2)
      
        expect(calculator.send(:state)).to include(node: :index, flow_state: :notify)
      end
    end  
   
    context 'switch back' do
      before do
        calculator.node_add(:index) do
          request {
            prompt 'Hello'
          }

          process {
            switch :yellow
          }
        end

        calculator.node_add(:yellow) do
          request {
            switch :back
          }
        end      
      end
      
      it 'switches correctly to the previous node' do
        calculator.apply
        calculator.apply 

        expect(calculator.send(:state)).to include(node: :index, flow_state: :request)
      end
    end

    context 'on invalid switch back' do
      before do
        calculator.node_add(:index) do
          request {
            switch :back
          }
        end
      end

      it 'throws an error on calling switch back' do
       expect { calculator.apply }.to raise_error Colloquy::JumpInvalidException
      end
    end

    context 'passes on control to the process block' do
      before do
        calculator.node_add(:index) do
          request { |input|
            pass if input == '1'
          }
          process { |input|
            notify 'Direct' if input.direct?
            
            case input
            when '1'
              switch :branch
            else
              notify 'Hello'
            end
          }
        end
          
        calculator.node_add(:branch)
      end
      
      it 'switches flow state when pass is encountered' do
        expect(calculator.apply(1)).to eq('Direct')
        expect(calculator.send(:state)).to include(node: :index, flow_state: :notify)
      end
    end
  end
  
  describe '#apply_request' do
    it 'stores menu state after a request block' do
      calculator.node_add(:index) do
        request { 
          menu.push(:a, :b, :c)
        }
        process { |input|
          case menu.key(input)
          when :a
            switch :branch
          when :b
            notify 'Hello'
          when :c
            notify 'C'
          else
            notify 'Nothing'
          end
        }
      end
      calculator.node_add(:branch)
      calculator.messages = { a: 'Apple', b: 'Boy', c: 'Cat' }
      calculator.apply

      expect(calculator.instance_variable_get(:@state)).to include(menu: { pages: [[:a, :b, :c]] })
    end
    
    it 'stores menu state even with larger menus' do
      calculator.node_add(:index) do
        request { 
          menu.push(*FLOW_PARSER_MENU_MESSAGES.keys)
        }
        process { |input|
          case menu.key(input)
          when :a
            switch :branch
          when :b
            notify 'Hello'
          when :c
            notify 'C'
          else
            notify 'Nothing'
          end
        }
      end
      calculator.node_add(:branch)
      calculator.messages = FLOW_PARSER_MENU_MESSAGES
      calculator.apply

      expect(calculator.instance_variable_get(:@state)).to include(menu: { pages: [[:a, :b, :c, :d, :e, :more], [:f, :g, :h, :i, :j, :k, :l, :previous, :more], [:m, :n, :o, :p, :q, :r, :s, :t, :u, :v, :w, :x, :y, :previous, :more], [:z, :previous]] })
    end
    
    it 'stores menu prefix and suffix state across requests' do
      calculator.node_add(:index) do
        request { 
          menu.prefix { 'Hello' }
          menu.push(*FLOW_PARSER_MENU_MESSAGES.keys)
          menu.suffix { 'World' }
        }
        process { |input|
          case menu.key(input)
          when :a
            switch :branch
          when :b
            notify 'Hello'
          when :c
            notify 'C'
          else
            notify 'Nothing'
          end
        }
      end
      
      calculator.messages = FLOW_PARSER_MENU_MESSAGES

      expect(calculator.apply).to eq("Hello\n1. Apple\n2. Boy\n3. Cat\n4. Created by Shigeru Miyamoto, Donkey-Kong is a series of video games that features the adventures of a large ape.\n5. more\nWorld")
      expect(calculator.apply(5)).to eq("Hello\n1. Elephant\n2. Fool\n3. God\n4. Hibiscus is a super plant! It is very red and blue and all.\n5. Idiot\n6. Joker\n7. previous\n8. more\nWorld")
    end
  end
  
  context 'stale sessions on flow reload' do
    before do
      calculator.node_add(:index) do
        request {
          session[:state] = 'Enter an input:'
        }
        
        process {
          
        }
      end
    end
    
    it 'throws an error when sessions reference a node which is no longer present in the flow' do
      calculator.apply
      calculator.send(:state)[:node] = :begin
      
      expect { calculator.apply }.to raise_error Colloquy::NodeNotFoundException
    end
  end
  
  context 'session access from the flow' do
    before do
      calculator.node_add(:index) do
        request {
          session[:state] = 'Hello, World!'
          switch :branch
        }
      end
      
      calculator.node_add(:branch) do
        request {
          notify session[:state]
        }
      end
    end
    
    it 'allows session access from the flow' do
      expect(calculator.apply).to eq('Hello, World!')
      expect(calculator.send(:state)).to include(node: :branch, flow_state: :notify)
    end
  end
  
  context 'user-defined method access from the flow' do
    before do
      class Calculator
        def add(first, second)
          first + second
        end
      end
      
      calculator.node_add(:index) do
        request {
          notify add(1, add(2, 3))
        }
      end
    end
    
    it 'allows accessing methods defined in the parent node from the flow' do
      expect(calculator.apply).to eq('6')
    end
  end
  
  context 'method undefined in both flow and node' do
    before do
      class Calculator
        def add(first, second)
          first + second
        end
      end
      
      calculator.node_add(:index) do
        request {
          notify subtract(1, -1)
        }
      end
    end
    
    it 'raises an error when accessing method undefined in both the flow and the node' do
      expect { calculator.apply }.to raise_error NoMethodError
    end
  end
  
  context 'paginated menus' do
    before do
      calculator.node_add(:index) do
        request { 
          menu.push(*FLOW_PARSER_MENU_MESSAGES.keys)
        }
        process { |input|
          case menu.key(input)
          when :a
            notify 'A selected'
          when :b
            notify 'B selected'
          when :c
            notify 'C selected'
          when :z
            notify 'Z selected'
          when :l
            notify 'L selected'
          when :m
            notify 'M selected'
          else
            notify 'Something else selected'
          end
        }
      end
      
      calculator.messages = FLOW_PARSER_MENU_MESSAGES
    end
    
    it 'should render a menu correctly' do
      expect(calculator.apply).to eq("1. Apple\n2. Boy\n3. Cat\n4. Created by Shigeru Miyamoto, Donkey-Kong is a series of video games that features the adventures of a large ape.\n5. Elephant\n6. more")
      expect(calculator.apply(1)).to eq('A selected')
    end
    
    it 'should re-render the menu when the more option is selected' do
      expect(calculator.apply).to eq("1. Apple\n2. Boy\n3. Cat\n4. Created by Shigeru Miyamoto, Donkey-Kong is a series of video games that features the adventures of a large ape.\n5. Elephant\n6. more")
      expect(calculator.apply(6)).to eq("1. Fool\n2. God\n3. Hibiscus is a super plant! It is very red and blue and all.\n4. Idiot\n5. Joker\n6. King Kong is super comedy\n7. Love\n8. previous\n9. more")
      expect(calculator.apply(9)).to eq("1. Mother\n2. Neat\n3. Open\n4. Princess\n5. Queen\n6. Reindeer\n7. Socrates\n8. Talktime\n9. Umbrella\n10. Victory\n11. Wonderful\n12. Xena\n13. YoYo\n14. previous\n15. more")
      expect(calculator.apply(15)).to eq("1. Zero\n2. previous")
      expect(calculator.apply(1)).to eq('Z selected')
    end

    it 'should go back to the previous menu when the previous option is selected' do
      expect(calculator.apply).to eq("1. Apple\n2. Boy\n3. Cat\n4. Created by Shigeru Miyamoto, Donkey-Kong is a series of video games that features the adventures of a large ape.\n5. Elephant\n6. more")
      expect(calculator.apply(6)).to eq("1. Fool\n2. God\n3. Hibiscus is a super plant! It is very red and blue and all.\n4. Idiot\n5. Joker\n6. King Kong is super comedy\n7. Love\n8. previous\n9. more")
      expect(calculator.apply(9)).to eq("1. Mother\n2. Neat\n3. Open\n4. Princess\n5. Queen\n6. Reindeer\n7. Socrates\n8. Talktime\n9. Umbrella\n10. Victory\n11. Wonderful\n12. Xena\n13. YoYo\n14. previous\n15. more")
      expect(calculator.apply(15)).to eq("1. Zero\n2. previous")
      expect(calculator.apply(2)).to eq("1. Mother\n2. Neat\n3. Open\n4. Princess\n5. Queen\n6. Reindeer\n7. Socrates\n8. Talktime\n9. Umbrella\n10. Victory\n11. Wonderful\n12. Xena\n13. YoYo\n14. previous\n15. more")
      expect(calculator.apply(14)).to eq("1. Fool\n2. God\n3. Hibiscus is a super plant! It is very red and blue and all.\n4. Idiot\n5. Joker\n6. King Kong is super comedy\n7. Love\n8. previous\n9. more")
      expect(calculator.apply(8)).to eq("1. Apple\n2. Boy\n3. Cat\n4. Created by Shigeru Miyamoto, Donkey-Kong is a series of video games that features the adventures of a large ape.\n5. Elephant\n6. more")
    end
    
    it 'should not fall off the end of the menu' do
      calculator.apply
      calculator.apply(6)
      calculator.apply(9)

      expect(calculator.apply(12)).to eq('Something else selected')
    end
    
    it 'should break off pagination if an option other than more is selected in between' do
      calculator.apply
      calculator.apply(6)
      calculator.apply(9)

      expect(calculator.apply(1)).to eq('M selected')
    end
  end

  context 'paginated menus with previous option disabled' do
    before do
      calculator.node_add(:index) do
        request { 
          menu.push(*FLOW_PARSER_MENU_MESSAGES.keys)
        }
        process { |input|
          case menu.key(input)
          when :a
            notify 'A selected'
          when :b
            notify 'B selected'
          when :c
            notify 'C selected'
          when :z
            notify 'Z selected'
          when :l
            notify 'L selected'
          when :m
            notify 'M selected'
          else
            notify 'Something else selected'
          end
        }
      end
      
      calculator.messages = FLOW_PARSER_MENU_MESSAGES.merge(previous: '')
    end
    
    it 'should re-render the menu without the previous option when the more option is selected' do
      expect(calculator.apply).to eq("1. Apple\n2. Boy\n3. Cat\n4. Created by Shigeru Miyamoto, Donkey-Kong is a series of video games that features the adventures of a large ape.\n5. Elephant\n6. more")
      expect(calculator.apply(6)).to eq("1. Fool\n2. God\n3. Hibiscus is a super plant! It is very red and blue and all.\n4. Idiot\n5. Joker\n6. King Kong is super comedy\n7. Love\n8. Mother\n9. more")
      expect(calculator.apply(9)).to eq("1. Mother\n2. Neat\n3. Open\n4. Princess\n5. Queen\n6. Reindeer\n7. Socrates\n8. Talktime\n9. Umbrella\n10. Victory\n11. Wonderful\n12. Xena\n13. YoYo\n14. Zero")
      expect(calculator.apply(1)).to eq('M selected')
    end

    it 'should break off pagination if an option other than more is selected in between' do
      calculator.apply
      calculator.apply(6)

      expect(calculator.apply(8)).to eq('M selected')
    end
  end

  
  context 'paginated prompts' do
    before do
      calculator.node_add(:index) do
        request {
          prompt FLOW_PARSER_PROMPT_MESSAGES[:d]
        }
        
        process { |input|
          notify 'Hello' if input == '1'
          notify 'World' if input == '2'
        }
      end
    end
    
    it 'should render a prompt correctly' do
      expect(calculator.apply).to eq("Created by Shigeru Miyamoto, Donkey-Kong \n is a series of video games that features the adventures of a large ape.\n Donkey-Kong is a series of video \n1. more")
    end
    
    it 'should render the prompt continued when the more option is selected' do
      expect(calculator.apply).to eq("Created by Shigeru Miyamoto, Donkey-Kong \n is a series of video games that features the adventures of a large ape.\n Donkey-Kong is a series of video \n1. more")
      expect(calculator.apply(1)).to eq("games that features the adventures of a large ape.\n Donkey-Kong is a series of video games that features the adventures of a large ape.")
    end
    
    it 'should not fall off the end of the pagination' do
      calculator.apply
      calculator.apply(1)

      expect(calculator.apply(1)).to eq('Hello')
    end
    
    it 'should break off pagination if an option other than more is selected in between' do
      calculator.apply
      calculator.apply(1)

      expect(calculator.apply(2)).to eq('World')
    end
  end
  
  context 'must be able to use the underscore function to compose messages both in the flow definition and in outside functions' do
    before do
      calculator.node_add(:index) do
        request {
          menu << :hello << :user
          prompt menu.render << "\n" << _(:branding)
        }
        
        process { |input|
          case input
          when '1'
            notify hello
          end
        }
      end
      
      class Calculator
        def hello
          _(:branding)
        end
      end
      
      calculator.messages = { branding: 'MobME Wireless!' }
    end
    
    it 'should work from the flow definitions' do
      expect(calculator.apply).to include 'MobME Wireless!'
    end
    
    it 'should work from the flow functions' do
      calculator.apply

      expect(calculator.apply(1)).to include 'MobME Wireless!'
    end
  end
  
  context 'within functions in the flow' do
    before do
      calculator.node_add(:index) do
        request { |input|
          hello(input)
        }
        
        process { |input|
          case input
          when '1'
            notify hello
          end
        }
      end
      
      calculator.node_add(:world) do
        request {
        }
        
        process { |input|
        }
      end
      
      class Calculator
        def hello(input)
          case input
          when '1'
            notify 'Hello'
          when '2'
            switch :world
          when '3'
            switch :world, :flow => :art_of_war
          when '4'
            pass
          else
            raise 'Failed!'
          end
        end
      end
    end
        
    it 'should be able to use notify' do
      expect(calculator.apply(1)).to eq('Hello')
    end
    
    it 'should be able to use switch' do
      calculator.apply(2)
      
      expect(calculator.send(:state)).to include(node: :world, flow_state: :request)
    end
    
    it 'should be able to switch between flows' do
      expect {
        calculator.apply(3)
      }.to raise_error { |error|
        expect(error.payload).to eq( node: :world, flow: :art_of_war )
      }
    end
    
    it 'should be able to pass' do
      calculator.apply(4)
      
      expect(calculator.send(:state)).to include(node: :index, flow_state: :process)
    end
  end
  
  context 'directly inside the flow' do
    before do
      calculator.node_add(:index) do
        request { |input|
          case input
          when '1'
            notify 'Hello'
          when '2'
            switch :world
          when '3'
            switch :world, flow: :art_of_war
          when '4'
            pass
          else
            raise 'Failed!'
          end
        }
        
        process { |input|
          case input
          when '1'
            notify hello
          end
        }
      end
      
      calculator.node_add(:world) do
        request {
        }
        
        process { |input|
        }
      end
    end
        
    it 'should be able to use notify' do
      expect(calculator.apply(1)).to eq('Hello')
    end
    
    it 'should be able to use switch' do
      calculator.apply(2)
      
      expect(calculator.send(:state)).to include(node: :world, flow_state: :request)
    end
    
    it 'should be able to switch between flows' do
      expect {
        calculator.apply(3)
      }.to raise_error { |error|
        expect(error).to be_kind_of Colloquy::SwitchFlowJump
        error.payload.should == { :node => :world, :flow => :art_of_war }
      }
    end
    
    it 'should be able to pass' do
      calculator.apply(4)
      
      expect(calculator.send(:state)).to include(node: :index, flow_state: :process)
    end
  end
  
  context 'must be able to add nodes using an Asterisk-like context syntax from within a class' do
    before do
      class Calculator
        index {
          request {
            notify 'Hello World!'
          }
        }
      end
    end
    
    it 'works' do
      expect(calculator.apply).to eq('Hello World!')
    end
  end
end
