require 'colloquy'
require 'ruby-prof'

#EM.synchrony do
  RENDERER_PATH_ROOT = Pathname.new(File.dirname(__FILE__)).join('examples')
  renderer = Colloquy::Renderer.new(path_root: RENDERER_PATH_ROOT)
  renderer.prepare!

  flow_name = :calculator
  msisdn = "9745044399"

  RubyProf.start
    5000.times do |session_id|
      4.times do 
        renderer.apply(flow_name, msisdn, session_id, 1)
      end
    end
  result = RubyProf.stop
  #Print a flat profile to text
  printer = RubyProf::FlatPrinter.new(result)
  printer.print(STDOUT)

#  EventMachine.stop
#end



