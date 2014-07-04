
class CalculatorFlow

  include Colloquy::FlowParser
  
  index {
    request {
      menu << "Add" << "Subtract" << "Back"
    }
    
    process { |input|
      session[:operation] = case menu.key(input)
        when "Add"
          :add
        when "Subtract"
          :subtract
        when "Back"
          switch :back
        else
          notify :operation_invalid
        end
      
      switch :number_first
    }
  }
  
  number_first {
    request {
      prompt "Enter the first number:"
    }
    
    process { |input|
      if valid_input? input
        session[:first_number] = input.to_i
        switch :number_second
      else
        notify :number_invalid
      end
    }
  }
  
  number_second {
    request {
      prompt "Enter the second number:"
    }
    
    process { |number|
      if valid_input? number
        value = calculate(session[:operation], session[:first_number], number.to_i)
        notify "The result is: #{value}"
      end
    }
  }
  
  def calculate(operation, first_number, second_number)
    case operation
    when :add
      first_number + second_number
    when :subtract
      first_number - second_number
    else
      logger.error "Got an unexpected operation."
      notify :error
    end
  end
  
  def valid_input?(number)
    "#{number.to_i}"
  end
end

