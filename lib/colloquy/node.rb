class Colloquy::Node
  attr_reader :identifier, :options
  attr_writer :flow
  
  def initialize(identifier = :index, options = {}, &block)
    @identifier = identifier.to_sym
    @flow = options[:flow] || nil
    @options = options.delete(:flow)
    
    instance_eval &block if block
  end
  
  def prompt(message)
    @prompt = Colloquy::Prompt.new(:message => message, :flow => @flow)
  end
  
  def prompt?
    @prompt && !@prompt.blank?
  end
  
  def menu?
    @menu && !@menu.empty?
  end

  def menu
    @menu ||= Colloquy::Menu.new(:flow => @flow)
  end
  
  def render
    if @prompt
      @prompt.render
    elsif !menu.empty?
      menu.render
    else
      ""
    end.strip
  end
  
  def method_missing(method, *arguments, &block)
    if @flow and @flow.respond_to? method
      @flow.send(method, *arguments, &block) 
    else
      raise NoMethodError, "#{method} is missing in the flow"
    end
  end
  
  def request(&block)
    @request_block = block 
  end
  
  def request!(input = nil)
    @request_block.call(input) if @request_block
  end
  
  def process(&block)
    @process_block = block 
  end
  
  def process!(input = nil)
    @process_block.call(input) if @process_block
  end

  def reset!
    @prompt = nil
    menu.reset!
  end
end