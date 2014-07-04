require 'em-synchrony'

class Colloquy::Simulator
  def initialize(options = {})
    @renderer = Colloquy::Renderer.new(options)
    @renderer.prepare!
  end

  def construct_response 
    @renderer.apply(@flow_name, @msisdn, @session_id, @input)
  end
  
  def run_simulator(input)
    response = construct_response
    puts response
    
    if response.flow_state == :notify
      puts "\n---Flow complete---"
      reset
    else
      read_input
    end
    
    run_simulator(@input)
  end
  
  def reset
    puts "\n--Going back to beginning of flow--\n"
    
    # Get a new session_id when the simulator is reset
    @session_id = @session_id.to_i + 1
    
    puts 'Initial input (for direct flow):'
    read_input
    
    run!
  end
  
  def ask_for_flow_parameters
    puts 'Please enter flow name:'
    @flow_name = EM::Synchrony.gets.strip
    puts 'Please enter msisdn: '
    @msisdn = EM::Synchrony.gets.strip
    puts 'Please enter session_id: '
    @session_id = EM::Synchrony.gets.strip
    puts 'Initial input (for direct flow): '
    read_input
  end
  
  # Run simulator inside EM.synchrony loop
  def run
    EM.synchrony do
      ask_for_flow_parameters
      run!
    end
  end
  
  def run!
    validate_request
    sanitize_parameters!
    
    run_simulator(@input)
  end
  
  private
  def read_input
    print '> '
    @input = EM::Synchrony.gets.strip
    sanitize_parameters!
    
    case @input 
    when 'reset'
      reset
    when 'quit'
      puts 'Bye!'
      exit!
    end
  end
  
  def logger
    @renderer.logger
  end
  
  def validate_request
    validate_flow_presence!
    validate_msisdn!
    validate_session_id!
  end
  
  def validate_flow_presence!
    unless @renderer.flow_exists?(@flow_name)
      raise Colloquy::FlowNotFound, "Flow not found: #{@flow_name}"
    end
  end
  
  def validate_msisdn!
    if @msisdn == ''
      raise Colloquy::MSISDNParameterEmpty, 'The msisdn parameter should not be empty.'
    end
  end
  
  def validate_session_id!
    if @session_id == ''
      raise Colloquy::SessionIDParameterEmpty, 'The session_id parameter should not be empty.'
    end
  end
  
  def sanitize_parameters!
    @flow_name = @flow_name.to_sym
    @msisdn = @msisdn.to_i.to_s
    @session_id = @session_id.to_s[0..20].strip
    @input = @input.to_s[0..160].strip
  end
end
