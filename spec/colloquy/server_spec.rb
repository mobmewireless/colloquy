require_relative '../spec_helper'

require 'goliath/test_helper'

describe Colloquy::Server do
  include Goliath::TestHelper

  SERVER_PATH_ROOT = Pathname.new(File.dirname(__FILE__)).join('..', '..', 'examples')

  before(:all) do
    Colloquy.root = SERVER_PATH_ROOT
  end

  before(:each) do
    allow(Colloquy::Helpers::MySQL::MySQLProxy.instance).to receive(:mysql_connection)
  end

  let(:request_error) { Proc.new { |resp| fail "API request failed: #{resp.inspect}" } }
  let(:common_queries) { {session_id: 8989, msisdn: 919846819066} }

  describe '#response' do
    it 'returns error unexpected when the flow throws an uncaught exception' do
      with_api(Colloquy::Server) do
        get_request({path: '/pass', query: common_queries}, request_error) do
          get_request({path: '/pass', query: common_queries.merge(input: 3)}, request_error) do |c|
            expect(c.response).to eq("{\"response\":\"We're facing technical difficulties at this time. Please try again later!\",\"flow_state\":\"notify\"}")
          end
        end
      end
    end

    it 'maps additional parameters as metadata in headers in the flow' do
      with_api(Colloquy::Server) do
        get_request({path: '/metadata', query: common_queries}, request_error) do |c|
          expect(c.response).to eq("{\"response\":\"I love \",\"flow_state\":\"notify\"}")
        end
      end

      with_api(Colloquy::Server) do
        get_request({path: '/metadata', query: common_queries.merge(love: 'Apple')}, request_error) do |c|
          expect(c.response).to eq("{\"response\":\"I love Apple\",\"flow_state\":\"notify\"}")
        end
      end
    end

    it 'returns only the response text when an accept parameter of text/plain is given' do
      with_api(Colloquy::Server) do
        get_request({path: '/metadata', query: common_queries.merge(accept: 'text/plain')}, request_error) do |c|
          expect(c.response).to eq('I love ')
        end
      end
    end
  end
end
