require 'singleton'
require 'yaml'

class Colloquy::SettingsConfigurationNotFoundException < Exception
end

class Colloquy::SettingsGemsNotFoundException < Exception
end

module Colloquy::Helpers::Settings
  def self.included(klass)
    klass.class_eval do
      include InstanceMethods
    end
  end

  class SettingsProxy
    include Singleton

    def configure
      return if configured?
      configure!
    end

    def configured?
      @configured
    end

    def configure!
      unless settings_configuration_file.exist?
        raise Colloquy::SettingsConfigurationNotFoundException, "Cannot find #{settings_configuration_file}"
      end

      begin
        require_settings_libraries
      rescue LoadError
        raise Colloquy::SettingsGemsNotFoundException, "Cannot load the required settings gems."
      end

      @settings_configurations ||= {}
      settings_configuration_load

      @configured = true
    end

    def settings_configuration_file
      Colloquy.root.join('config', 'settings.yaml')
    end

    def require_settings_libraries
      require "yaml"
    end

    def settings_configuration_load
      return unless settings_configuration_exists?

      @settings_configuration_entries = File.open(settings_configuration_file, "r") { |f| YAML.load(f.read) }

      if @settings_configuration_entries
        @settings_configuration_entries.each do |identifier, params|
          @settings_configurations[identifier.to_sym] = settings_configuration(params)
        end
      else
        raise Colloquy::SettingsConfigurationNotFoundException, "Cannot find configuration in #{settings_configuration_file}. Is it empty?"
      end
    end

    def settings_configuration_exists?
      settings_configuration_file.exist?
    end

    def [](identifier)
      unless @settings_configurations[identifier.to_sym]
        raise Colloquy::SettingsFileNotFoundException, "A settings file for #{identifier} was not found, did you mis-spell or forget to configure it?"
      end

      @settings_configurations[identifier.to_sym]
    end

    def settings_configuration(params)
      begin
        if params[0] == "/"
          yaml = YAML::load(File.open(params))
        else
          yaml = YAML::load(File.open(Colloquy.root.join(params)))
        end
      rescue Errno::ENOENT => e
        logger.error "File not found: #{params}"
        return {}
      rescue Psych::SyntaxError => e
        logger.error "File #{params} is not valid YAML"
        return {}
      end
    end

    def logger
      Colloquy.logger
    end

  end


  module InstanceMethods
    def settings
      SettingsProxy.instance.configure

      SettingsProxy.instance
    end
  end

end
