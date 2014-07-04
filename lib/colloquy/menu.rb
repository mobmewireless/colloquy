
class Colloquy::Menu
  include Colloquy::Paginator
  
  attr_accessor :keys, :flow
  
  def initialize(options = {})
    @flow = options[:flow] || nil
    @page = options[:page] || 1
    @prefix = options[:prefix]
    @suffix = options[:suffix]
    @keys = []
  end
  
  def render(page = @page)    
    paginate unless @pages
    
    assemble_prefix
    assemble_suffix
    
    execute_before_page_hook
    "#{render_prefix}#{render_body(page)}#{render_suffix}"
  end
  
  def key(input, page = @page)
    state = @flow.send(:state)
    
    return false unless input.to_i.to_s == input
    return false if input.to_i > @pages[page - 1].size
    
    key = if @pages
      @pages[page - 1][input.to_i - 1]
    end
    
    if key.respond_to? :push
      key.first
    else
      key
    end
  end
  
  def push(*args)
    @keys.push(*args)
  end
  
  def <<(symbol)
    @keys << symbol
    
    self
  end
  
  def empty?
    @keys.empty?
  end
  
  def [](symbol)
    @keys[symbol]
  end
  
  def freeze
    @keys.freeze
  end
  
  def prefix(&block)
    @prefix_block = block
  end
  
  def suffix(&block)
    @suffix_block = block
  end
  
  def prefix=(string)
    @prefix = string
  end
  
  def suffix=(string)
    @suffix = string
  end
  
  def reset!
    @keys = []
    @pages = nil
    @page = 1
    @prefix = nil
    @suffix = nil
  end
  
  private  
  def assemble_prefix(options = {})
    @flow.tap do |f|
      current_page_for_menu = f.headers[:page]
      f.headers[:page] = options[:page] if options[:page]
      
      @prefix = f.instance_eval &@prefix_block if @prefix_block
      
      f.headers[:page] = current_page_for_menu
    end
  end
  
  def assemble_suffix(options = {})
    @flow.tap do |f|
      current_page_for_menu = f.headers[:page]
      f.headers[:page] = options[:page] if options[:page]
      
      @suffix = @flow.instance_eval &@suffix_block if @suffix_block
      
      f.headers[:page] = current_page_for_menu
    end
  end
  
  def assemble
    @assembled_strings = @keys.collect do |item|
      render_each(item)
    end
  end
  
  def render_each(item)
    "#{Colloquy::MessageBuilder.to_message(item, :flow => @flow)}"
  end
  
  def render_prefix
    @prefix ? "#{@prefix}\n" : ""
  end
  
  def render_suffix
    @suffix ? "\n#{@suffix}" : ""  
  end
end
