require_relative '../../spec_helper'

require 'em-http'
require 'em-synchrony'
require 'em-synchrony/em-http'

describe Colloquy::Helpers::Url do
  PATH_ROOT = Pathname.new(File.dirname(__FILE__)).join('..', '..', '..', '..', '..', 'examples') unless defined? PATH_ROOT
  
  let(:example_renderer) { Colloquy::Renderer.new(path_root: PATH_ROOT) }
  let(:url_helper) { 
    class URLIncluded
      include Colloquy::Helpers::Url
    end.new
  }
  
  it 'should throw an error if urls.yaml is not found' do
    begin
      FileUtils.mv(PATH_ROOT.join('config', 'urls.yaml'), PATH_ROOT.join('config', 'urls-invalid.yaml'))
      Colloquy::Renderer.new(path_root: PATH_ROOT)

      expect { url_helper.url }.to raise_error URLAgent::ConfigurationNotFoundException
    ensure
      FileUtils.mv(PATH_ROOT.join('config', 'urls-invalid.yaml'), PATH_ROOT.join('config', 'urls.yaml'))
    end
  end
  
  it 'should respond to get and post methods' do
    EM.synchrony do
      expect(url_helper.url[:log_cancellations].build(msisdn: 9846819066).get.response).to include '301 Moved'
      EM.add_timer(0.5) { EM.stop }
    end
  end
end
