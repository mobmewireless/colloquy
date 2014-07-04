class Colloquy::SessionStore::Memory < Colloquy::SessionStore

  def []=(key, value)    
    @store ||= {}
    @store[normalized_key_name(key)] = encode_value(value)
  end
  
  def [](key)
    @store ||= {}
    string = @store[normalized_key_name(key)]
    
    decode_value(string)
  end
end
