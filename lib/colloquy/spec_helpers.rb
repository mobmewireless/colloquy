
# These are helper methods you might find useful when 
# writing flow specs
module Colloquy::SpecHelpers
  def stub_mysql!
    allow(ActiveRecord::Base).to receive(:establish_connection)
    allow(Colloquy::Helpers::MySQL::MySQLProxy).to receive(:instance).and_return(
      double('MySQLProxy', configure: nil, configuration: {})
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
