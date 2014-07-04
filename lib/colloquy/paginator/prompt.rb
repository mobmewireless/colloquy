
module Colloquy::Paginator::Prompt
  private
  def paginate
    
    message_body = Colloquy::MessageBuilder.to_message(@message, flow: @flow)

    allowed_length = maximum_response_length(message_body)

    @pages = []
    
    if message_body.length < allowed_length
      @pages << message_body
    else
      # allowed message length is from renderer; depends on character encoding
      length = allowed_length - (render_more.length + 3 + 1)
      @pages = message_body.squeeze(' ').scan(/\b.{1,#{length}}(?:$|\b)/m)
      
      @pages[0..-2].map! { |page| page << "\n1. " << render_more }
      
      @pages
    end
  end
  
  def render_body(page)
    @pages[page - 1]
  end
  
  def render_more
    @rendered_more ||= Colloquy::MessageBuilder.to_message(:more, flow: @flow)
  end
end
