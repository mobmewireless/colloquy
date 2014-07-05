
require_relative '../spec_helper'

describe Colloquy::Node do
  let(:node) { Colloquy::Node.new }
  
  before(:each) do
    Colloquy.maximum_message_length = 160
    
    flow = double('flow', messages: { hello: 'Hello, World!', user: 'Vishnu', branding: 'Powered by Colloquy' }, headers: {})
    node.instance_variable_set(:@flow, flow)
  end
  
  it 'takes a identifier :symbol as a parameter' do
    Colloquy::Node.new(:index)
  end
  
  it 'takes a identifier string as a parameter' do
    Colloquy::Node.new('index')
  end
  
  it 'has a prompt method that sets the current prompt' do
    node.instance_eval do 
      request {
        prompt 'Hello, World!'
      }
    end
    
    node.request!
    
    expect(node.instance_variable_get(:@prompt)).to eq('Hello, World!')
  end
  
  it 'takes a block that is instance_evaled on the node to generate a DSL' do
    new_node = Colloquy::Node.new do
      request {
        prompt 'Hello, World!'
      }
    end
    
    new_node.request!
    
    expect(new_node.instance_variable_get(:@prompt)).to eq('Hello, World!')
  end
  
  context '#menu' do
    it 'exists' do
      node.instance_eval do
        request {
          menu
        }
      end
      
      node.request!
    end
      
    context '#<<' do
      it 'takes one parameter' do
        node.instance_eval do
          request {
            menu << 'Hello World'
          }
        end
        
        node.request!
      end
      
      it 'can have multiple definitions' do
        node.instance_eval do
          request {
            menu << 'Hello'
            menu << 'World'
          }
        end
        
        node.request!
      end
      
      it 'can be chained' do
        node.instance_eval do
          request {
            menu << 'Hello' << 'World'
          }
        end
        
        node.request!
      end
    end
    
    it 'must be rendered in order' do
      node.instance_eval do
        request {
          menu << 'Hello' << 'World'
        }
      end
      
      node.request!
      
      expect(node.render).to eq("1. Hello\n2. World")
    end
  end
  
  context '#render' do
    it 'renders the prompt if set' do
      node.instance_eval do
        request {
          prompt 'Hello, World!'
        }
      end
      
      node.request!
      expect(node.render).to eq('Hello, World!')
    end
    
    it 'renders the menu if present' do
      node.instance_eval do
        request {
          menu << 'Hello' << 'World'
        }
      end
    
      node.request!
      expect(node.render).to eq("1. Hello\n2. World")
    end
    
    it 'renders the prompt if both a prompt and menu are present' do
      node.instance_eval do
        request {
          prompt 'Hello, World!'
          menu << 'Hello' << 'World'
        }
      end
      
      node.request!
      expect(node.render).to eq('Hello, World!')
    end

    it 'renders nothing if no prompt or menu are present, and no flow is given' do
      expect(node.render).to eq('')
    end
    
    context 'message handling' do
      before(:each) do
        flow = double('flow', messages: { hello: 'Hello, World!', user: 'Vishnu', branding: 'Powered by Colloquy' }, headers: {})
        node.instance_variable_set(:@flow, flow)
      end
      
      it 'should map message symbols to the actual text content in a prompt' do
        node.instance_eval do
          request {
            prompt :hello
          }
        end
        
        node.request!
        expect(node.render).to eq('Hello, World!')
      end
      
      it 'should map message symbols to the actual text content in a menu' do
        node.instance_eval do
          request {
            menu << :hello << :user
          }
        end
        
        node.request!
        expect(node.render).to eq("1. Hello, World!\n2. Vishnu")
      end
      
      it 'is possible to render the menu' do
        node.instance_eval do
          request {
            menu << :hello << :user
            
            prompt menu.render
          }
        end
        
        node.request!
        expect(node.render).to eq "1. Hello, World!\n2. Vishnu"
      end
    end
  end

  context '#process' do
    it 'accepts a block' do
      node.instance_eval do 
        process {
        }
      end
    end
    
    it 'calls that block when #process! is called' do
      node.instance_eval do 
        process {
          1 + 1
        }
      end
      
      expect(node.process!).to eq(2)
    end
    
    it 'calls the block with an input when #process!(input) is called' do
      node.instance_eval do 
        process { |input|
          input + 1
        }
      end
      
      expect(node.process!(2)).to eq(3)
    end
    
    it 'returns nil when #process! is called without a block' do
      expect(node.process!).to be_nil
    end
  end
  
  context '#request' do
    it 'accepts a block' do
      node.instance_eval do 
        request {
        }
      end
    end
    
    it 'calls that block when #request! is called' do
      node.instance_eval do 
        request {
          1 + 1
        }
      end
      
      expect(node.request!).to eq(2)
    end
    
    it 'calls the block with an input when #request!(input) is called' do
      node.instance_eval do 
        request { |input|
          input + 1
        }
      end
      
      expect(node.request!(2)).to eq(3)
    end
    
    it 'returns nil when #request! is called without a block' do
      expect(node.request!).to be_nil
    end
  end  
end