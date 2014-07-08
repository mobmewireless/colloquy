require_relative '../../spec_helper'

require 'scribe-logger'

describe Colloquy::Helpers::Scribe do
  SCRIBE_PATH_ROOT = Pathname.new(File.dirname(__FILE__)).join('..', '..', '..', 'examples')

  let(:example_renderer) { Colloquy::Renderer.new(path_root: SCRIBE_PATH_ROOT) }
  let(:scribe_helper) {
    class ScribeIncluded
      include Colloquy::Helpers::Scribe
    end.new
  }

  before(:each) do
    @scribe_mock = double(Scribe)
    allow(Scribe).to receive(:loggers).and_return(@scribe_mock)
  end

  describe '#configure' do
    it 'should throw an error if scribe.yaml is not found' do
      begin
        FileUtils.mv(SCRIBE_PATH_ROOT.join('config', 'scribe.yaml'), SCRIBE_PATH_ROOT.join('config', 'scribe-invalid.yaml'))
        Colloquy::Renderer.new(path_root: SCRIBE_PATH_ROOT)

        expect { scribe_helper.scribe.configure! }.to raise_error Colloquy::ScribeConfigurationNotFoundException
      ensure
        FileUtils.mv(SCRIBE_PATH_ROOT.join('config', 'scribe-invalid.yaml'), SCRIBE_PATH_ROOT.join('config', 'scribe.yaml'))
      end
    end

    it 'should throw an error if required libraries are not present' do
      allow(Colloquy::Helpers::Scribe::ScribeProxy.instance).to receive(:require_scribe_libraries).and_raise(LoadError)

      expect { scribe_helper.scribe.configure! }.to raise_error Colloquy::ScribeGemsNotFoundException
    end

    it 'should read configuration from the provided file' do
      expect(scribe_helper.scribe.configured?).to be true
      expect(scribe_helper.scribe.instance_variable_get(:@scribe_connections).keys).to include(:testing)
    end

    it 'should throw errors on invalid YAML in scribe.yaml'

    it 'should throw errors on invalid configuration keys in scribe.yaml'

  end

  describe '#[]' do
    it 'should return the Scribe object' do
      scribe_helper.scribe.configure!

      expect(scribe_helper.scribe[:testing]).to be @scribe_mock
    end
  end

end
