
class DatabaseFlow
  include Colloquy::FlowParser
  
  index {
    request {
      menu << :activate << :cancel
    }
    
    process { |input|
      case menu.key(input)
      when :activate
        privileged_user = mysql[:customer].query("select sleep(0.25);")
        if privileged_user
          if activate(headers[:msisdn])
            notify :activation_success
          else
            notify :activation_failure
          end
        else
          notify :priveleges_required
        end
      when :cancel
        url.call(:log_cancellations, { :msisdn => headers[:msisdn] })
        notify :canceled
      end
    }
  }
  
  def activate(msisdn)
    logger.info "Activating #{msisdn}!"
  end
end
