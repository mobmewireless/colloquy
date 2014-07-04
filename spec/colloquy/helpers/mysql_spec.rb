require_relative '../../spec_helper'

require 'fileutils'
require 'em-synchrony/mysql2'

describe Colloquy::Helpers::MySQL do
  PATH_ROOT = Pathname.new(File.dirname(__FILE__)).join('..', '..', '..', 'examples')

  let(:example_renderer) { Colloquy::Renderer.new(path_root: PATH_ROOT) }
  let(:mysql_helper) {
    class MySQLIncluded
      include Colloquy::Helpers::MySQL
    end.new
  }

  before(:each) do
    @em_mysql_mock = double(Mysql2::EM::Client)

    Colloquy::Helpers::MySQL::MySQLProxy.instance.stub(:mysql_connection).and_return(@em_mysql_mock)
  end

  describe '#configure' do
    it 'should throw an error if mysql.yaml is not found' do
      begin
        FileUtils.mv(PATH_ROOT.join('config', 'mysql.yaml'), PATH_ROOT.join('config', 'mysql-invalid.yaml'))
        Colloquy::Renderer.new(path_root: PATH_ROOT)

        expect { mysql_helper.mysql.configure! }.to raise_error Colloquy::MySQLConfigurationNotFoundException
      ensure
        FileUtils.mv(PATH_ROOT.join('config', 'mysql-invalid.yaml'), PATH_ROOT.join('config', 'mysql.yaml'))
      end
    end

    it 'should throw an error if required libraries are not present' do
      Colloquy::Helpers::MySQL::MySQLProxy.instance.stub(:require_mysql_libraries).and_raise(LoadError)

      expect { mysql_helper.mysql.configure! }.to raise_error Colloquy::MySQLGemsNotFoundException
    end

    it 'should read configuration from the provided file' do
      expect(mysql_helper.mysql.configured?).to be_true
      expect(mysql_helper.mysql.instance_variable_get(:@mysql_db_connections).keys).to include(:testing)
    end

    it 'should throw errors on invalid YAML in mysql.yaml'

    it 'should throw errors on invalid configuration keys in mysql.yaml'
  end

  describe '#[]' do
    it 'should return the EM::MySQL object' do
      mysql_helper.mysql.configure!

      expect(mysql_helper.mysql[:testing]).to eq @em_mysql_mock
    end
  end
end
