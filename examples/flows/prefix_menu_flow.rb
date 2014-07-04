
class PrefixMenuFlow
  include Colloquy::FlowParser
  
  index {
    request { |input|
      menu.push(headers[:msisdn])
      menu.push(*('a'..'z').to_a)
      menu.prefix { "Hello #{headers[:session_id]}" }
      menu.suffix do
        logger.info "Headers: #{headers.inspect}"
        "Your world is my oyster! And there's nothing better than beer! Or a touch of lemonade." if headers[:page] == 1
      end
      
      menu.before_page do
        session[:wonker] = "Page: #{headers[:page]}"
      end
    }
    
    process { |input|
      notify menu.key(input)
    }
  }
end
