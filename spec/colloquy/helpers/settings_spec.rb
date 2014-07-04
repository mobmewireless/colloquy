require_relative '../../spec_helper'

require 'fileutils'
require 'yaml'
require 'fakefs/safe'

describe Colloquy::Helpers::Settings do
  SETTINGS_PATH_ROOT = Pathname.new(File.dirname(__FILE__)).join('..', '..', '..', 'examples')

  let(:example_renderer) { Colloquy::Renderer.new(path_root: SETTINGS_PATH_ROOT) }
  let(:settings_helper) {
    class SettingsIncluded
      include Colloquy::Helpers::Settings
    end.new
  }

  before(:each) do
    logger_double = double('Logger', error: nil, warn: nil, info: nil, debug: nil)
    allow(Colloquy).to receive(:logger).and_return logger_double
  end

  describe '#configure' do
    it 'should throw an error if settings.yaml is not found' do
      begin
        FileUtils.mv(SETTINGS_PATH_ROOT.join('config', 'settings.yaml'), SETTINGS_PATH_ROOT.join('config', 'settings-invalid.yaml'))
        Colloquy::Renderer.new(path_root: SETTINGS_PATH_ROOT)

        expect { settings_helper.settings.configure! }.to raise_error Colloquy::SettingsConfigurationNotFoundException
      ensure
        FileUtils.mv(SETTINGS_PATH_ROOT.join('config', 'settings-invalid.yaml'), SETTINGS_PATH_ROOT.join('config', 'settings.yaml'))
      end
    end

    it 'should throw an error if required libraries are not present' do
      Colloquy::Helpers::Settings::SettingsProxy.instance.stub(:require_settings_libraries).and_raise(LoadError)

      expect { settings_helper.settings.configure! }.to raise_error Colloquy::SettingsGemsNotFoundException
    end

    it 'should read configuration from the provided file' do
      expect(settings_helper.settings.configured?).to be_true
      expect(settings_helper.settings.instance_variable_get(:@settings_configurations).keys).to include(:testing)
    end

    it 'should throw errors on invalid YAML in settings.yaml'

    it 'should throw errors on invalid configuration keys in settings.yaml'
  end

  describe '#[]' do
    it 'should return the settings hash' do
      settings_mock = double(YAML)
      allow(Colloquy::Helpers::Settings::SettingsProxy.instance).to receive(:settings_configuration).and_return(settings_mock)
      settings_helper.settings.configure!

      expect(settings_helper.settings[:testing]).to eq settings_mock
    end
  end

  describe '#settings_configuration' do
    context 'opens the yaml file passed on to it as params' do
      before(:each) { allow(YAML).to receive(:load).and_return({}) }

      it 'when file path is relative' do
        expect(File).to receive(:open).with Colloquy.root.join('config/test.yaml')

        settings_helper.settings.settings_configuration('config/test.yaml')
      end

      it 'when file path is absolute' do
        expect(File).to receive(:open).with('/home/user/projects/ussd-redux/examples/config/test.yaml')

        settings_helper.settings.settings_configuration('/home/user/projects/ussd-redux/examples/config/test.yaml')
      end
    end

    it 'parses the opened file' do
      mock_file = double(File)
      allow(File).to receive(:open).and_return(mock_file)

      expect(YAML).to receive(:load).with(mock_file).and_return({})

      settings_helper.settings.settings_configuration('config/test.yaml')
    end

    it 'returns the parsed content' do
      allow(File).to receive(:open)
      allow(YAML).to receive(:load).and_return({})

      expect(settings_helper.settings.settings_configuration('config/test.yaml')).to eq({})
    end

    it 'writes ERROR to log and returns an empty hash on invalid YAML' do
      FakeFS.activate!

      File.open('invalid_yaml.yaml', 'w') do |f|
        f.puts 'hello'
        f.puts 'hello:'
        f.puts '  123 - yaml:'
        f.puts 'string'
      end
      file_stream = File.open('invalid_yaml.yaml')
      allow(File).to receive(:open).and_return(file_stream)

      expect(settings_helper.settings.settings_configuration('config/invalid_yaml.yaml')).to eq({})

      FakeFS.deactivate!
    end

    it 'writes ERROR to log and returns an empty hash when configuration file is not present' do
      expect(settings_helper.settings.settings_configuration('config/tet.yaml')).to eq({})
    end
  end
end
