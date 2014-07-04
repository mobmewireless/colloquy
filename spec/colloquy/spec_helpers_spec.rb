require_relative '../spec_helper'
require 'colloquy/spec_helpers'
require 'active_record'

# In an actual spec this would be your flow in a different file
class SpecHelperCalculator
  include Colloquy::FlowParser
  
  index {
    request {
      prompt "Please enter your input:"
    }
    
    process { |input|
      session[:input] ||= []
      session[:input] << input.to_i
      
      if session[:input].length == 2
        switch :calculate
      else
        switch :index
      end
    }
  }
  
  calculate {
    request {
      prompt "#{session[:input].inject(&:+)}"
    }
  }
  
  def setup
    ActiveRecord::Base.establish_connection(mysql.configuration['test'])
  end
end

# Include the SpecHelpers
include Colloquy::SpecHelpers


describe SpecHelperCalculator do
  let(:calculator) do 
    SpecHelperCalculator.new
  end
  
  before(:all) do
    SPEC_HELPERS_RENDERER_PATH_ROOT = Pathname.new(File.dirname(__FILE__)).join("..", "..", "..", "..", "examples")
    Colloquy::Renderer.new(:path_root => SPEC_HELPERS_RENDERER_PATH_ROOT)
  end
  
  describe "stub_mysql!" do
    it "should properly stub out MysQL" do
      stub_mysql!
      calculator
    end
  end
  
  describe "apply_chain" do
    it "should work with chained inputs" do
      stub_mysql!
      apply_chain(calculator, nil, 2, 3).last.should == "5"
    end
  end
  
  describe "state_for" do
    it "should return the flow state" do
      stub_mysql!
      state_for(calculator).should == {:node=>:index, :flow_state=>:init, :previous=>{}, :flow_name=>:spec_helper_calculator}
      
      calculator.apply
      
      state_for(calculator).should == {:node=>:index, :flow_state=>:request, :previous=>{:node=>:index, :flow_state=>:init, :flow_name=>:spec_helper_calculator}, :flow_name=>:spec_helper_calculator, :back=>{:node=>:index, :flow_name=>:spec_helper_calculator}, :prompt=>["Please enter your input:"], :page=>1}
    end
  end
end
