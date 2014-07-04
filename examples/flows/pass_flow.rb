
class PassFlow
  include Colloquy::FlowParser
  
  index {
    request { |input|
      pass unless input.blank?
      menu << :activate << :cancel
    }
    
    process { |input|
      notify :direct if input.direct?

      case menu.key(input)
      when :activate
        notify :activation_success
      when :cancel
        cancelation = url[:log_cancellations].call(:msisdn => headers[:msisdn])
        notify cancelation.response
      else
        notif "Hello World!" #Deliberate error!
      end
    }
  }
  
  def activate
    logger.info "Activating!"
  end
end
