require 'singleton'
require 'yaml'
require 'active_support/core_ext/hash'

class Colloquy::MySQLConfigurationNotFoundException < Exception
end

class Colloquy::MySQLGemsNotFoundException < Exception
end

class Colloquy::MySQLConnectionNotFoundException < Exception
end

module Colloquy::Helpers::MySQL
  def self.included(klass)
    klass.class_eval do
      include InstanceMethods
    end
  end
  
  class MySQLProxy
    DEFAULT_OPTIONS = { :host => "localhost", :port => 3306, :socket => "/tmp/mysql.sock", :username => "root", :password => "", :reconnect => true, :pool => 5}
    
    include Singleton
    
    def initialize
      @configured = false
    end
    
    def configure
      return if configured?
      configure!
    end
    
    def configure!
      unless mysql_configuration_file.exist?
        raise Colloquy::MySQLConfigurationNotFoundException, "Cannot find #{mysql_configuration_file}"
      end

      begin
        require_mysql_libraries
      rescue LoadError
        raise Colloquy::MySQLGemsNotFoundException, "Cannot load the mysql2 gem."
      end    

      @mysql_db_connections ||= {}
      mysql_configuration_load
      
      @configured = true
    end
    
    def configured?
      @configured
    end
    
    def require_mysql_libraries
      require "em-synchrony/mysql2"
    end
    
    def [](identifier)
      unless @mysql_db_connections[identifier.to_sym]
        raise Colloquy::MySQLConnectionNotFoundException, "A connection for #{identifier} was not found, did you mis-spell or forget to configure it?"
      end
            
      @mysql_db_connections[identifier.to_sym]
    end
    
    def configuration
      @mysql_configuration_entries
    end
    
    private
    
    def mysql_configuration_file
      Colloquy.root.join('config', 'mysql.yaml')
    end

    def mysql_configuration_load
      return unless mysql_configuration_exists?

      @mysql_configuration_entries = File.open(mysql_configuration_file, "r") { |f| YAML.load(f.read) }
      @mysql_configuration_entries.to_options!
      
      if @mysql_configuration_entries
        @mysql_configuration_entries.each do |identifier, params|
          params.to_options!.merge!(DEFAULT_OPTIONS) { |key, v1, v2| v1 }
          @mysql_db_connections[identifier.to_sym] = mysql_connection(params)
        end
      else
        raise Colloquy::MySQLConfigurationNotFoundException, "Cannot find configuration in #{mysql_configuration_file}. Is it empty?"
      end
    end
    
    def mysql_connection(params)
      Mysql2::EM::Client.new(params)
    end

    def mysql_configuration_exists?
      mysql_configuration_file.exist?
    end
  end
  
  module InstanceMethods
    def mysql
      MySQLProxy.instance.configure
      
      MySQLProxy.instance
    end
  end
end
