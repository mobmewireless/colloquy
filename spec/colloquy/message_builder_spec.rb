require_relative '../spec_helper'
require 'active_support/core_ext/string'

describe Colloquy::MessageBuilder do
  MESSAGES = {
      hello_test: 'Hello',
      hello_user: 'Hello %{user}',
      hello_users: 'Hello %{user1} & %{user2}',
      hello_user_native: 'Hello %{user}',
      hello_users_native: 'Hello %{user1} & %{user2}',
      hello: {
          :world => 'America!',
          :user => 'Vishnu',
          :love => '%{name} girl!',
          :token => {
              :extract => 'Pineapple!'
          }
      }
  }
  MB = Colloquy::MessageBuilder

  subject(:message_builder) { Colloquy::MessageBuilder }
  
  describe '#to_message' do
    it 'should get messages from the flow' do
      flow = double('flow', messages: MESSAGES)

      expect(message_builder.to_message(:hello_test, flow: flow)).to eq('Hello')
    end

    
    it 'should get messages from a messages array' do
      expect(message_builder.to_message(:hello_test, messages: MESSAGES)).to eq('Hello')
    end
    
    it 'should return the symbol as a string if the emergent message is not found' do
      flow = double('flow', messages: MESSAGES)

      expect(message_builder.to_message(:unknown, flow: flow)).to eq('unknown')
      expect(message_builder.to_message(:unknown, messages: MESSAGES)).to eq('unknown')
      expect(message_builder.to_message('Hello, big bright world!', messages: MESSAGES)).to eq('Hello, big bright world!')
    end
    
    it 'should handle multiple calls to to_message correctly displaying substitutions each time' do
      flow = double('flow', messages: MESSAGES)

      expect(message_builder.to_message([:hello_user, user: 'Vishnu'], flow: flow)).to eq('Hello Vishnu')
      expect(message_builder.to_message([:hello_user, user: 'Hari'], flow: flow)).to eq('Hello Hari')
    end
    
    context 'parameterized messages' do
      it 'should handle parameterized messages' do
        expect(message_builder.to_message([:hello_user, { user: 'Vishnu'}], messages: MESSAGES)).to eq('Hello Vishnu')
      end
      
      it 'should handle multiple parameters' do
        expect(message_builder.to_message([:hello_users, user1: 'Vishnu', user2: 'Hari'],
          messages: MESSAGES)).to eq('Hello Vishnu & Hari')
      end
      
      it 'should handle parameters from the flow' do
        flow = double('flow', :messages => MESSAGES)

        expect(message_builder.to_message([:hello_user, user: 'Vishnu'], flow: flow)).to eq('Hello Vishnu')
      end
    end
    
    context 'native parameterization' do
      it 'should handle parameterized messages' do
        expect(message_builder.to_message([:hello_user_native, user: 'Vishnu'], messages: MESSAGES)).to eq('Hello Vishnu')
      end
      
      it 'should handle multiple parameters' do
        expect(message_builder.to_message([:hello_users_native, user1: 'Vishnu', user2: 'Hari'],
          messages: MESSAGES)).to eq('Hello Vishnu & Hari')
      end
      
      it 'should handle parameters from the flow' do
        flow = double('flow', :messages => MESSAGES)

        expect(message_builder.to_message([:hello_user_native, user: 'Vishnu'], flow: flow)).to eq('Hello Vishnu')
      end
    end
    
    context 'deep hashes' do
      it 'should substitute from hashes' do
        expect(message_builder.to_message(:hello_world, messages: MESSAGES)).to eq('America!')
      end
      
      it 'should work with nested hashes' do
        expect(message_builder.to_message(:hello_token_extract, messages: MESSAGES)).to eq('Pineapple!')
      end
      
      it 'should substitute variables in nested hashes' do
        expect(message_builder.to_message([:hello_love, name: 'Double M'], messages: MESSAGES)).to eq('Double M girl!')
      end
      
      it 'should prefer straight substitution to deep hashes' do
        expect(message_builder.to_message([:hello_user, user: 'Vishnu'], messages: MESSAGES)).to eq('Hello Vishnu')
      end
    end
  end
end
