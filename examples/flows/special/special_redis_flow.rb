
class RedisFlow
  include Colloquy::FlowParser
  
  index {
    request {
      menu << :activate << :cancel << :back
    }
    
    process { |input|
      case menu.key(input)
      when :activate
        notify :activation_success
      when :cancel
        cancelation = redis[:testing].set("canceled", "true: #{headers[:msisdn]}")
        notify redis[:testing].get("canceled")
      when :back
        switch :back
      else
        notify "Hello World!"
      end
    }
  }
  
  def activate
    logger.info "Activating!"
  end
end
