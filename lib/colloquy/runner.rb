require 'goliath/api'
require 'goliath/runner'

require 'goliath/rack/default_response_format'
require 'goliath/rack/heartbeat'
require 'goliath/rack/params'
require 'goliath/rack/render'
require 'goliath/rack/default_mime_type'
require 'goliath/rack/tracer'
require 'goliath/rack/formatters/json'
require 'goliath/rack/formatters/html'
require 'goliath/rack/formatters/xml'
require 'goliath/rack/jsonp'

require 'goliath/rack/validation/request_method'
require 'goliath/rack/validation/required_param'
require 'goliath/rack/validation/required_value'
require 'goliath/rack/validation/numeric_range'
require 'goliath/rack/validation/default_params'
require 'goliath/rack/validation/boolean_value'

class Colloquy::Runner
  class << self
    # Much of this is borrowed verbatim from Goliath internals so we 
    # can use our own class structure
    def run!(argv)
      options = {}
      goliath_argv = []

      option_parser = OptionParser.new do |opt|
        opt.banner = 'Usage: colloquy [options] /path/to/flow/root'
        
        opt.on('-a', '--address HOST', 'Hostname or IP address to bind to') do |host|
          goliath_argv << '-a' << host
        end
        
        opt.on('-p', '---port PORT', 'Port to run the server on') do |port|
          goliath_argv << '-p' << port
        end
        
        opt.on('-e', '---environment ENV', 'Rack environment to run the renderer') do |env|
          goliath_argv << '-e' << env
          options[:environment] = env
        end
        
        opt.on('-P', '--pidfile PATH_TO_FILE', 'Location to write the PID file to') do |pid_file|
          goliath_argv << '-P' << pid_file
        end
        
        opt.on('-d', '--daemonize', 'Daemonize the server') do
          goliath_argv << '-d'
        end
        
        opt.on('-v', '--verbose', 'Turn on debug logging') do
          goliath_argv << '-v'
          options[:verbose] = true
        end
        
        opt.on('-s', '--simulator', 'Run the flow simulator instead') do
          options[:interactive] = true
        end
        
        opt.on( '-h', '--help', 'Display this screen' ) do
          puts opt
          exit!
        end
      end
      
      option_parser.parse!(argv)
      
      path_root = argv.pop
      unless path_root
        puts 'You have to provide a flow root directory. See colloquy --help'
        exit!
      end
      
      goliath_argv << '-l' << Pathname.new(path_root).realpath.join('log', 'server.log').to_s
      
      if options[:interactive]
        simulator = Colloquy::Simulator.new(path_root: path_root, verbose: options[:verbose])
        simulator.run
      else      
        klass = Colloquy::Server
        api = klass.new(path_root: path_root, verbose: options[:verbose])
        runner = Goliath::Runner.new(goliath_argv, api)

        runner.app = Goliath::Rack::Builder.build(klass, api)
        runner.load_plugins(klass.plugins)
        runner.run
      end
    end
  end
end
