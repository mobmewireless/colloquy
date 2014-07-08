require 'singleton'
require 'yaml'

class Colloquy::ScribeConfigurationNotFoundException < Exception
end

class Colloquy::ScribeGemsNotFoundException < Exception
end

class Colloquy::ScribeConnectionNotFoundException < Exception
end

module Colloquy::Helpers::Scribe
  def self.included(klass)
    klass.class_eval do
      include InstanceMethods
    end
  end

  class ScribeProxy
    include Singleton

    def initialize
      @configured = false
    end

    def configure
      return if configured?
      configure!
    end

    def configure!
      unless scribe_configuration_file.exist?
        raise Colloquy::ScribeConfigurationNotFoundException, "Cannot find #{scribe_configuration_file}"
      end

      begin
        require_scribe_libraries
      rescue LoadError
        raise Colloquy::ScribeGemsNotFoundException, "Cannot load the scribe gem."
      end

      @scribe_connections ||= {}
      scribe_configuration_load

      @configured = true
    end

    def configured?
      @configured
    end

    def connections
      @scribe_connections
    end

    def [](identifier)
      unless @scribe_connections[identifier.to_sym]
        raise Colloquy::ScribeConnectionNotFoundException, "A connection for #{identifier} was not found, did you mis-spell or forget to configure it?"
      end

      @scribe_connections[identifier.to_sym]
    end

    def require_scribe_libraries
      require 'scribe-logger'
    end

    def scribe_configuration_file
      Colloquy.root.join('config', 'scribe.yaml')
    end

    def scribe_configuration_load
      return unless scribe_configuration_exists?

      scribe_configuration = File.open(scribe_configuration_file, "r") { |f| YAML.load(f.read) }

      if scribe_configuration
        scribe_configuration.each do |identifier, params|
          @scribe_connections[identifier.to_sym] = scribe_connection(params)
        end
      else
        raise Colloquy::ScribeConfigurationNotFoundException, "Cannot find configuration in #{scribe_configuration_file}. Is it empty?"
      end
    end

    def scribe_connection(params)
      Scribe.loggers(params)
    end

    def scribe_configuration_exists?
      scribe_configuration_file.exist?
    end
  end

  module InstanceMethods
    def scribe
      ScribeProxy.instance.configure
      ScribeProxy.instance
    end
  end

end
