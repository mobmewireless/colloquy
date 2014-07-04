
class Colloquy::Input < String
  attr_accessor :direct
  
  def initialize(input)
    @direct = input.respond_to?(:direct) ? input.direct : false
    
    super(input.to_s)
  end
  
  def direct?
    @direct
  end
end
