# encoding: UTF-8
require_relative '../spec_helper'

describe Colloquy::Prompt do
  PROMPT_MESSAGES = {
    :a => "Apple", :b => "Boy", :c => "Cat", 
    :d => "Created by Shigeru Miyamoto, Donkey-Kong 
      is a series of video games that features the adventures of a large ape.
      Donkey-Kong is a series of video games that features the adventures of a large ape.
      Donkey-Kong is a series of video games that features the adventures of a large ape.",
    :e => "This prompt message ends with a letter. It does not end with a digit, or a new line character or a special character;
           repeat after me - This prompt message ends with a letter"
  }

  UNICODE_MESSAGES = {
      a: 'മനസ്സിലായില്ല',
      b: 'പുലികളുടെ സംസ്ഥാന സമ്മേളനം നടക്കുന്ന സ്ഥിതിക്ക് ഒരു ഓഫ്/റിലേറ്റഡ് സംശയം ചോദിച്ചോട്ടാ',
      c: 'സോഫ്റ്റ്വെയര് എന്നെഴുതുമ്പോഴും കൌ എന്നെഴുതുമ്പോഴും ഒരു രക്ഷയുമില്ല എന്നതാണ്. വിക്കിയില് അത് അങ്ങനെതന്നെയിടും ചിലപ്പോഴ് കോപ്പി ചെയ്ത് വെച്ചിട്ടുള്ള ഒരു'
  }
  
  before(:each) do
    Colloquy.maximum_message_length = 160
    Colloquy.maximum_unicode_length = 70
  end

  describe '#render' do
    let(:flow) do
      double('flow', messages: PROMPT_MESSAGES.merge(more: 'More'))
    end

    it 'should render a simple page' do
      prompt = Colloquy::Prompt.new(flow: flow, message: PROMPT_MESSAGES[:a])

      expect(prompt.render).to eq('Apple')
    end

    it 'should render a simple page when message is passed as a symbol' do
      prompt = Colloquy::Prompt.new(flow: flow, message: :a)

      expect(prompt.render).to eq('Apple')
    end
    
    it 'should render subsequent pages' do
      prompt = Colloquy::Prompt.new(flow: flow, message: PROMPT_MESSAGES[:d])

      expect(prompt.render(1)).to eq("Created by Shigeru Miyamoto, Donkey-Kong \n is a series of video games that features the adventures of a large ape.\n Donkey-Kong is a series of video \n1. More")
      expect(prompt.render(2)).to eq("games that features the adventures of a large ape.\n Donkey-Kong is a series of video games that features the adventures of a large ape.")
    end

    it 'should render subsequent pages when message is passed as a symbol' do
      prompt = Colloquy::Prompt.new(flow: flow, message: :d)

      expect(prompt.render(1)).to eq("Created by Shigeru Miyamoto, Donkey-Kong \n is a series of video games that features the adventures of a large ape.\n Donkey-Kong is a series of video \n1. More")
      expect(prompt.render(2)).to eq("games that features the adventures of a large ape.\n Donkey-Kong is a series of video games that features the adventures of a large ape.")
    end

    it 'should render subsequent pages of messages that end with a character' do
      prompt = Colloquy::Prompt.new(flow: flow, message: PROMPT_MESSAGES[:e])

      expect(prompt.render(1)).to eq("This prompt message ends with a letter. It does not end with a digit, or a new line character or a special character;\n repeat after me - This prompt \n1. More")
      expect(prompt.render(2)).to eq('message ends with a letter')
    end
    
    it 'should not render messages with length greater than the standard USSD message length' do
      prompt = Colloquy::Prompt.new(flow: flow, message: PROMPT_MESSAGES[:d])
      length = Colloquy.maximum_message_length
      
      (1..prompt.total_pages).each do |page|
        expect(prompt.render(page).length).to be <= length
      end
    end
  end

  describe '#render - unicode messages' do
    let(:flow) do
      double('flow', messages: UNICODE_MESSAGES.merge(more: 'More'))
    end

    it 'should render a simple unicode message' do
      prompt = Colloquy::Prompt.new(flow: flow, message: UNICODE_MESSAGES[:a])

      expect(prompt.render).to eq('മനസ്സിലായില്ല')
    end

    it 'should render a simple unicode message when message is passed as a symbol' do
      prompt = Colloquy::Prompt.new(flow: flow, message: :a)

      expect(prompt.render).to eq('മനസ്സിലായില്ല')
    end

    it 'should render lengthy unicode messages' do
      prompt = Colloquy::Prompt.new(flow: flow, message: UNICODE_MESSAGES[:b])

      expect(prompt.render(1)).to eq("പുലികളുടെ സംസ്ഥാന സമ്മേളനം നടക്കുന്ന സ്ഥിതിക്ക് ഒരു ഓഫ്/\n1. More")
      expect(prompt.render(2)).to eq('റിലേറ്റഡ് സംശയം ചോദിച്ചോട്ടാ')
    end

    it 'should render subsequent pages when message is passed as a symbol' do
      prompt = Colloquy::Prompt.new(flow: flow, message: :c)

      expect(prompt.render(1)).to eq("സോഫ്റ്റ്വെയര് എന്നെഴുതുമ്പോഴും കൌ എന്നെഴുതുമ്പോഴും ഒരു \n1. More")
      expect(prompt.render(2)).to eq("രക്ഷയുമില്ല എന്നതാണ്. വിക്കിയില് അത് അങ്ങനെതന്നെയിടും \n1. More")
      expect(prompt.render(3)).to eq('ചിലപ്പോഴ് കോപ്പി ചെയ്ത് വെച്ചിട്ടുള്ള ഒരു')
    end
    
  end
end
