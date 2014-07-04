
class Colloquy::MessageBuilder
  class << self
    def to_message(message_emergent, options = {})
      message_emergent, parameters = extract_parameters(message_emergent)
      message = replace_from_options(message_emergent, options)
      message = substitute_parameters(message, parameters)
      message.to_s
    end
    
    private
    def extract_parameters(message_emergent)
      parameters = nil
      
      if message_emergent.respond_to? :push
        parameters = message_emergent.last
        message_emergent = message_emergent.first
      end
      
      [message_emergent, parameters]
    end
    
    def replace_from_options(message_emergent, options)
      messages = if options[:flow]
        options[:flow].messages
      else
        options[:messages]
      end
      
      # try a direct match
      message = messages["#{message_emergent}".to_sym] if messages
      
      # try a match converting underscores to hash indices
      unless message
        message =
          begin
            message_emergent_as_keys = message_emergent.to_s.split('_').map(&:to_sym)
          
            message_emergent_as_keys.inject(messages) { |message_substituted, key| message_substituted[key] }
          rescue TypeError
            nil
          rescue NoMethodError
            nil
          end
      end
      
      message || "#{message_emergent}"
    end
    
    def substitute_parameters(message, parameters)      
      message % parameters
    end
  end
end
