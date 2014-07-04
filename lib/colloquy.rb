
require 'pathname'
require 'logger'

    module Colloquy
    class << self
        attr_reader :root
        attr_accessor :logger
        attr_writer :maximum_message_length, :maximum_unicode_length
        
        def root=(path)
          @root = Pathname.new("#{File.expand_path(path || Dir.pwd)}").realdirpath
        end        
        
        def maximum_message_length
          @maximum_message_length || 160
        end

        def maximum_unicode_length
          @maximum_unicode_length || 70
        end
      end
    end

require_relative 'colloquy/logger'
require_relative 'colloquy/message_builder'
require_relative 'colloquy/session_store'
require_relative 'colloquy/response'
require_relative 'colloquy/renderer'
require_relative 'colloquy/input'
require_relative 'colloquy/paginator'
require_relative 'colloquy/prompt'
require_relative 'colloquy/menu'
require_relative 'colloquy/flow_parser'
require_relative 'colloquy/node'
require_relative 'colloquy/simulator'
require_relative 'colloquy/server'
require_relative 'colloquy/exceptions'
require_relative 'colloquy/flow_pool'
