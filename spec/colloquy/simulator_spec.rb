require_relative '../spec_helper'

require 'em-synchrony'
require 'em-synchrony/mysql2'

describe Colloquy::Simulator do

  subject(:simulator) { Colloquy::Simulator.new(path_root: RENDERER_PATH_ROOT)}

  before(:each) do
    em_mysql_mock = double(Mysql2::EM::Client)

    allow(Colloquy::Helpers::MySQL::MySQLProxy.instance).to receive(:mysql_connection).and_return(em_mysql_mock)
  end

  context 'On asked to run' do
    before do
      allow(EM).to receive(:synchrony).and_yield
      allow(subject).to receive(:ask_for_flow_parameters)
      allow(subject).to receive(:run!)
    end

    it 'should ask for flow parameters and run' do
      expect(subject).to receive(:ask_for_flow_parameters)
      expect(subject).to receive(:run!)

      subject.run
    end
  end
end