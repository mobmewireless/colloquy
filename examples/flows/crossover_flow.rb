
class CrossoverFlow

  include Colloquy::FlowParser
  
  index {
    request { |input|
      session[:calculator_type] = (input == "1") ? :scientific : :normal 
      pass
    }
    
    process { |input|
      switch :index, :flow => :calculator
    }
  }
end

