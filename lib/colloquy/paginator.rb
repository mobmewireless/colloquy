
module Colloquy::Paginator
  def self.included(klass)
    if defined? Colloquy::Menu and klass == Colloquy::Menu
      require_relative 'paginator/menu'
      
      klass.class_eval do
        include Colloquy::Paginator::Menu
      end
    elsif defined? Colloquy::Prompt and klass == Colloquy::Prompt
       require_relative 'paginator/prompt'
       
       klass.class_eval do
         include Colloquy::Paginator::Prompt
       end
    end
    
    klass.class_eval do
      attr_accessor :page, :pages
      
      include Colloquy::Paginator::Common
    end
  end
  
  module Common
    def total_pages
      paginate unless @pages
      
      @pages.length
    end
    
    def page_available?(page)
      paginate unless @pages
      
      page <= @pages.length && page > 0
    end
    
    def paginate!
      paginate
    end
    
    def before_page(&block)
      @before_page_block = block
    end
    
    def maximum_response_length(message)
      if message.to_s.ascii_only?
        Colloquy.maximum_message_length
     else
        Colloquy.maximum_unicode_length
     end
    end
    
    private
    def execute_before_page_hook(&block)
      @flow.instance_eval &@before_page_block if @before_page_block
    end
  end
end
