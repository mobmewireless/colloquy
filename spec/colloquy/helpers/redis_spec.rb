require_relative '../../spec_helper'

require 'fileutils'
require 'em-redis'

describe Colloquy::Helpers::Redis do
  PATH_ROOT = Pathname.new(File.dirname(__FILE__)).join('..', '..', '..', '..', '..', 'examples') unless defined? PATH_ROOT

  let(:example_renderer) { Colloquy::Renderer.new(path_root: PATH_ROOT) }
  let(:redis_helper) {
    class RedisIncluded
      include Colloquy::Helpers::Redis
    end.new
  }

  before(:each) do
    @em_redis_mock = double(EM::Protocols::Redis, set: true, get: 'Hello')

    Colloquy::Helpers::Redis::RedisProxy.instance.stub(:redis_connection).and_return(@em_redis_mock)
  end

  describe '#configure' do
    it 'should throw an error if redis.yaml is not found' do
      begin
        FileUtils.mv(PATH_ROOT.join('config', 'redis.yaml'), PATH_ROOT.join('config', 'redis-invalid.yaml'))
        Colloquy::Renderer.new(path_root: PATH_ROOT)

        expect { redis_helper.redis }.to raise_error Colloquy::RedisConfigurationNotFoundException
      ensure
        FileUtils.mv(PATH_ROOT.join('config', 'redis-invalid.yaml'), PATH_ROOT.join('config', 'redis.yaml'))
      end
    end

    it 'should throw an error if required libraries are not present' do
      Colloquy::Helpers::Redis::RedisProxy.instance.stub(:require_redis_libraries).and_raise(LoadError)

      expect { redis_helper.redis }.to raise_error Colloquy::RedisGemsNotFoundException
    end

    it 'should read configuration from the provided file' do
      expect(redis_helper.redis.configured?).to be_true
      expect(redis_helper.redis.instance_variable_get(:@redis_connections)).to include(testing: @em_redis_mock)
    end

    it 'should throw errors on invalid YAML in redis.yaml'

    it 'should throw errors on invalid configuration keys in redis.yaml'
  end

  describe '#[]' do
    it 'should return the EM::Protocols::Redis connection' do
      redis_helper.redis.configure!

      expect(redis_helper.redis[:testing]).to eq @em_redis_mock
    end
  end
end
