
require_relative '../../spec_helper'

require 'em-redis'
require 'colloquy/session_store'
require 'colloquy/session_store/redis'

describe Colloquy::SessionStore::Redis do
  before do
    @redis_stub = double('EM::Protocols::Redis', set: true, get: "\x04\bI\"\nHello\x06:\x06ET")
    @redis = Colloquy::SessionStore::Redis.new(identifier: :session)
    @redis.stub(:redis_connection).and_return(@redis_stub)
  end
  
  it 'should take adequate options' do
    Colloquy::SessionStore::Redis.new(identifier: :session)
  end
  
  it 'should set and retrieve the key with a standard name and expiry' do
    expect(@redis_stub).to receive(:set).with(Colloquy::SessionStore::Redis::KEY_PREFIX + 'session' + ':' + 'hello', "\x04\bI\"\nHello\x06:\x06EF", Colloquy::SessionStore::Redis::KEY_EXPIRY)
    expect(@redis_stub).to receive(:get).with(Colloquy::SessionStore::Redis::KEY_PREFIX + 'session' + ':' + 'hello')

    @redis['hello'] = 'Hello'

    expect(@redis['hello']).to eq'Hello'
  end
  
  it 'should encode complex objects' do
    @redis_stub.should_receive(:set).with(Colloquy::SessionStore::Redis::KEY_PREFIX + 'session' +':' + 'hello',
      "\x04\b{\a:\nworldI\"\x13ten_ton_hammer\x06:\x06EF:\rprevious{\x06;\x00I\"\x11hello world!\x06;\x06F",
      Colloquy::SessionStore::Redis::KEY_EXPIRY)
    
    @redis['hello'] = { world: 'ten_ton_hammer', previous: { world: 'hello world!' } }
  end
end
