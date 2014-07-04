
class Colloquy::Prompt
  include Colloquy::Paginator
  
  attr_accessor :flow
  
  def initialize(options = {})
    @message = options[:message] || ''
    @page = options[:page] || 1
    @flow = options[:flow] || nil
  end
  
  def render(page = @page)
    paginate unless @pages
    
    execute_before_page_hook
    "#{render_body(page)}"
  end
  
  def ==(string)
    @message == string
  end
  
  def freeze
    @message.freeze
  end
  
  def key(input)
    if input.to_s == '1'
      :more
    else
      :unknown
    end
  end
end
