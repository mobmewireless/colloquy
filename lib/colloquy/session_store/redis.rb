class Colloquy::SessionStore::Redis < Colloquy::SessionStore
  KEY_EXPIRY = 300 # 5 minutes
  
  def []=(key, value)    
    @store ||= redis_connection
    @store.set(normalized_key_name(key), encode_value(value), KEY_EXPIRY)
  end
  
  def [](key)
    @store ||= redis_connection
    string = @store.get(normalized_key_name(key))
    
    decode_value(string)
  end
  
  private
  def redis_connection
    @redis = Colloquy::Helpers::Redis::RedisProxy.instance
    @redis.configure
    
    @redis[@identifier]
  end
  
end
