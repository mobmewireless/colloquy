class Colloquy::SessionStore
  KEY_PREFIX = 'ussd_renderer:'

  class << self
    # Returns a Memory store object according to the type of memory.
    # @param [Symbol, Hash], Type and Options
    # @return [Colloquy::SessionStore::Memory Colloquy::SessionStore::Redis]
    def haystack(type = :memory, options = {})
      case type.to_sym
      when :memory
        require_relative 'session_store/memory'

        Colloquy::SessionStore::Memory.new(options)
      else :redis
        require_relative 'session_store/redis'
        
        Colloquy::SessionStore::Redis.new(options)
      end
    end
  end 

  def initialize(options = {})
    @identifier = options[:identifier] || :sessions
  end

  private
  def normalized_key_name(key)
    KEY_PREFIX + @identifier.to_s + ":" + key.to_s
  end

  def encode_value(value)
    Marshal.dump(value)
  end
  
  def decode_value(string)
    if string
      Marshal.load(string)
    else
      {}
    end
  rescue TypeError
    {}
  rescue ArgumentError
    {}
  end
end
