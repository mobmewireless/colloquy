
class UrlFlow
  include Colloquy::FlowParser
  
  index {
    request {
      url[:log_cancellations].build(:msisdn => headers[:msisdn]).call
      menu << :activate << :cancel
    }
    
    process { |input|
      case menu.key(input)
      when :activate
        notify :activation_success
      when :cancel
        cancelation = url[:log_cancellations].build(:msisdn => headers[:msisdn]).call
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
