require 'goliath/api'
require 'goliath/runner'
require 'goliath/rack/params'

require 'em-synchrony'
require 'em-synchrony/em-http'
require 'yajl'

class Colloquy::Server < Goliath::API
  use Goliath::Rack::Params   # parse and merge query and body parameters

  # Create an instance of Colloquy::Renderer with given options
  # and set's it up
  # @param options [Hash] The options hash.
  def initialize(options = {})
    @renderer = Colloquy::Renderer.new(options)
    @renderer.prepare!
  end

  # This methods overrides #response of Goliath::API.
  # So this is where parameters are validated and fed to an instance of Renderer.
  # This methods returns response array with a http 200 status and body on successful execution.
  #
  # It validates the incoming request by checking presence of flow, msisdn and session_id. It sanitizes
  # the parameters and obtains a hash containing flow, msisdn, session_id and input. Any exception raised
  # at this point is rescued and a default error message is stored in response.
  #
  # After validation params are passed on the #apply method of instance of Renderer which was created and
  # configured in Server constructor.
  #
  # @param [Goliath::Env] env The request environment.
  # @return [Array] Array contains [Status code, Headers Hash, Body]
  def response(env)
    response = Colloquy::Response.new

    begin
      parameters = {}
      parameters = validate_request(env)
      parameters = sanitize_parameters(parameters)
      logger.debug "REQUEST flow: #{parameters[:flow_name]}, msisdn: #{parameters[:msisdn]}, \
        session_id: #{parameters[:session_id]}, input: #{parameters[:input]}, other: #{parameters[:params].inspect}"
    rescue Exception => e
      logger.error "Exception #{e.inspect} when trying to validate request flow: #{parameters[:flow_name]}, \
        msisdn: #{parameters[:msisdn]}, session_id: #{parameters[:session_id]}, input: #{parameters[:input]}"
      logger.debug "#{e.backtrace.inspect}"
      logger.info 'Responding with default error message'

      response = Colloquy::Response.new(Colloquy::Renderer::DEFAULT_ERROR_MESSAGE)
      response.flow_state = :notify
    end

    response = @renderer.apply(parameters[:flow_name], parameters[:msisdn], parameters[:session_id], parameters[:input], parameters[:params]) if response.empty?

    body = case parameters[:params][:accept]
           when 'text/plain'
             response.to_s
           else
             Yajl.dump({ response: response, flow_state: response.flow_state })
           end

    [200, {}, body]
  end

  private
  def logger
    @renderer.logger
  end

  # Validate request and return parameters
  # @param [Goliath::Env] env The request environment
  # @return [Hash] parameters The extracted parameters
  def validate_request(env)
    parameters = extract_request_parameters

    validate_flow_presence!(parameters)
    validate_msisdn!(parameters)
    validate_session_id!(parameters)

    parameters
  end

  # Create a hash with all request parameters combined
  # @return [Hash] The request parameters
  def extract_request_parameters
    flow_name = env['REQUEST_PATH'][1..-1].to_s

    # Use dup to preserve original env.
    params = env['params'].dup.to_options
    msisdn = params.delete(:msisdn).to_s
    session_id = params.delete(:session_id).to_s
    input = params.delete(:input).to_s

    {
        flow_name: flow_name,
        params: params,
        msisdn: msisdn,
        session_id: session_id,
        input: input
    }
  end

  # Check if required flow is present. Raise FlowNotFound exception if not
  # @param [Hash] parameters Extracted request parameters
  # @return [nil]
  # @raise [Colloquy::FlowNotFound]
  #   if flow is not present
  def validate_flow_presence!(parameters)
    unless @renderer.flow_exists?(parameters[:flow_name])
      raise Colloquy::FlowNotFound, "Flow not found: #{parameters[:flow_name]}"
    end
  end

  # Checks whether msisdn is present, raises MSISDNParameterEmpty if not
  # @param [Hash] parameters The paramters hash
  # @return [nil]
  # @raise [Colloquy::MSISDNParameterEmpty]
  #   if msisdn parameter not present
  def validate_msisdn!(parameters)
    if parameters[:msisdn] == ''
      raise Colloquy::MSISDNParameterEmpty, 'The msisdn parameter should not be empty.'
    end
  end

  # Checks whether session_id is present
  # @param [Hash] parameters The parameters hash
  # @return [nil]
  # @raise [Colloquy::SessionIDParameterEmpty]
  #   if session_id not present
  def validate_session_id!(parameters)
    if parameters[:session_id] == ''
      raise Colloquy::SessionIDParameterEmpty, 'The session_id parameter should not be empty.'
    end
  end

  # Clean parameter values(exact type, size etc)
  # @param [Hash] parameters The Parameters hash
  # @return [Hash] Parameters Sanitized parameters hash
  def sanitize_parameters(parameters)
    flow_name = parameters[:flow_name].to_sym
    msisdn = parameters[:msisdn].to_i.to_s
    session_id = parameters[:session_id].to_s[0..20]
    input = parameters[:input].to_s[0..160]

    #remove default proc so that the hash can be serialized using Marshal
    params = parameters[:params].tap do |p|
      p.default = nil
    end

    {
        flow_name: flow_name,
        params: params,
        msisdn: msisdn,
        session_id: session_id,
        input: input
    }
  end
end
