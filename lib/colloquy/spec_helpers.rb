
# These are helper methods you might find useful when 
# writing flow specs
module Colloquy::SpecHelpers
  def stub_mysql!
    ActiveRecord::Base.stub(:establish_connection)
    Colloquy::Helpers::MySQL::MySQLProxy.stub(:instance).and_return(
      double("MySQLProxy", :configure => nil, :configuration => {})
    )
  end
  
  def apply_chain(flow, *inputs)
    inputs.map do |input|
      flow.apply(input)
    end
  end
  
  def state_for(flow)
    flow.send(:state)
  end
end
