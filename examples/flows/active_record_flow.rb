
require 'active_record'

require_relative '../models/activations'

class ActiveRecordFlow
  include Colloquy::FlowParser
  
  index {
    request {
      menu << :activate << :cancel
    }
    
    process { |input|
      case menu.key(input)
      when :activate
        privileged_user = true
        if privileged_user
          if count = activate(headers[:msisdn])
            notify [:activation_success, :count => count]
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
  
  def setup
    ::Activation.establish_connection(mysql.configuration[:customer])
  end
  
  def activate(msisdn)
    logger.info "Activating #{msisdn}!"
    count = Activation.count
  end
end
