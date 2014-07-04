
module Colloquy::Paginator::Menu
  private
  def paginate
    assemble unless @assembled_strings

    @pages = []
    
    if @assembled_strings.join("\n").length + (3 * @assembled_strings.length) < allowed_menu_length(:without_more => true)
      @pages << @keys.compact
    else
      accumulator = []
      accumulator_keys = []
      
      @assembled_strings.zip(@keys).each do |string, key|        
        accumulator << string
        accumulator_keys << key
        
        if accumulator.join("\n").length + (3 * accumulator.length) > allowed_menu_length(:page => @pages.length + 1)
          if @pages.empty? or render_previous.empty?
            @pages << accumulator_keys[0..-2].compact.push(:more)
          else
            @pages << accumulator_keys[0..-2].compact.push(:previous).push(:more)
          end
          accumulator = [accumulator[-1]]
          accumulator_keys = [accumulator_keys[-1]]
        end
      end

      total_options_in_menu = @pages.flatten.length - (@pages.length * 2) + 1

      if total_options_in_menu < @assembled_strings.length
          @pages << @keys[total_options_in_menu..-1]
          @pages.last << :previous unless render_previous.empty?
      end
    end

    @assembled_strings = nil
    
    @pages
  end
  
  def allowed_menu_length(options = {})
    # This comes last, and is of the form:
    # "\nX. <More Text>"
    more_length = 1 + 3 + "#{render_more}".length 
    previous_length = 1 + 3 + "#{render_previous}".length 
    
    more_length = 0 if options[:without_more]
    previous_length = 0 if options[:without_more]
    previous_length = 0 if options[:page] == 1
    
      
    # Assemble the prefix and suffix again because they can change based on the page
    assemble_prefix(:page => options[:page] || 1)
    assemble_suffix(:page => options[:page] || 1)
    
    # maximum_message_length is from the renderer!
    maximum_response_length(@assembled_strings) - (render_prefix.length + render_suffix.length + more_length + previous_length)
  end
  
  def render_body(page = 1)
    menu = @pages[page - 1].dup

    menu = menu.each_with_index.map do |option, index| 
      "#{index + 1}. #{render_each(option)}"
    end

    menu.join("\n")
  end
  
  def render_more
    @rendered_more ||= Colloquy::MessageBuilder.to_message(:more, :flow => @flow)
  end

  def render_previous
    @rendered_previous ||= Colloquy::MessageBuilder.to_message(:previous, :flow => @flow)
  end
end
