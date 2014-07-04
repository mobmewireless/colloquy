require 'singleton'
require 'yaml'

class Colloquy::RedisConfigurationNotFoundException < Exception
end

class Colloquy::RedisGemsNotFoundException < Exception
end

class Colloquy::RedisConnectionNotFoundException < Exception
end

module Colloquy::Helpers::Redis
  def self.included(klass)
    klass.class_eval do
      include InstanceMethods
    end
  end
  
  class RedisProxy
    include Singleton
    
    def initialize
      @configured = false
    end
    
    def configure
      return if configured?
      configure!
    end
    
    def configure!
      unless redis_configuration_file.exist?
        raise Colloquy::RedisConfigurationNotFoundException, "Cannot find #{redis_configuration_file}"
      end

      begin
        require_redis_libraries
      rescue LoadError
        raise Colloquy::RedisGemsNotFoundException, "Cannot load the em-redis gem."
      end    

      @redis_connections ||= {}
      redis_configuration_load
      
      @configured = true
    end
    
    def configured?
      @configured
    end
    
    def require_redis_libraries
      require "em-redis"
      require "em-synchrony"
      require "em-synchrony/em-redis"
    end
    
    def [](identifier)
      unless @redis_connections[identifier.to_sym]
        raise Colloquy::RedisConnectionNotFoundException, "A Redis connection for #{identifier} was not found, did you mis-spell or forget to configure it?"
      end
            
      @redis_connections[identifier.to_sym]
    end
    
    private
    
    def redis_configuration_file
      Colloquy.root.join('config', 'redis.yaml')
    end

    def redis_configuration_load
      return unless redis_configuration_exists?

      redis_configuration = File.open(redis_configuration_file, "r") { |f| YAML.load(f.read) }
      
      if redis_configuration
        redis_configuration.each do |identifier, params|
          @redis_connections[identifier.to_sym] = redis_connection(params.to_options)
        end
      else
        raise Colloquy::RedisConfigurationNotFoundException, "Cannot find configuration in #{redis_configuration_file}. Is it empty?"
      end
    end
    
    def redis_connection(params = {})
      EM::Protocols::Redis.connect(params)
    end

    def redis_configuration_exists?
      redis_configuration_file.exist?
    end
  end
  
  module InstanceMethods
    def redis
      RedisProxy.instance.configure
      
      RedisProxy.instance
    end
  end
end
