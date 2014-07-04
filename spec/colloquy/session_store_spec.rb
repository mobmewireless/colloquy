require_relative '../spec_helper'

require 'em-redis'

describe Colloquy::SessionStore do
  SESSION_STORE_PATH_ROOT = Pathname.new(File.dirname(__FILE__)).join('..', '..', '..', '..', 'examples')
  
  describe '.haystack' do
    it 'should return a Memory store when the type is memory' do
      expect(Colloquy::SessionStore.haystack(:memory).class).to eq(Colloquy::SessionStore::Memory)
    end
    
    it 'should return a Redis store when the type is redis' do
      expect(Colloquy::SessionStore.haystack(:redis).class).to eq(Colloquy::SessionStore::Redis)
    end
  end  
end
