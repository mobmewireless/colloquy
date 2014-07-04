require 'yaml'
require 'active_support/inflector'
require 'active_support/core_ext/hash'
require 'colloquy/logger'

class Colloquy::Renderer
  DEFAULT_ERROR_MESSAGE = 'This service is not available at present. Please try again later!'
  
  attr_reader :logger

  # Extracts root path from options hash and creates a HashWithIndifferentAccess object using options.
  #
  # @param [Hash] options The options hash
  def initialize(options = {})
    Colloquy.root = options[:path_root] if options[:path_root]
    @options = options.with_indifferent_access
  end

  # Initializes renderer components if given configuration is valid.
  # The #configure it executes does lots of initializations and configurations. For details see the method.
  def prepare!
    configure if configuration_valid?
  end

  # This method is the only endpoint of Renderer used by Server#response. It receives flow_name, msisdn, session_id, input and metadata
  # provided by Server and returns response after doing lots of stuff with the input.
  #
  # It makes a session key for each received call, fetches a flow instance corresponding to it (which is an instance
  # of some class with module FlowParser mixed in), and pass all this to #apply!
  #
  # @return [Response] response The processed response
  def apply(flow_name, msisdn, session_id, input = nil, metadata = {})
    response = ''
    flow_state = :notify
    
    begin
      session_key = make_session_key(msisdn, session_id)
      state, session, flow = state_load(flow_name, session_key, metadata)

      response = apply!(flow, state, session, session_key, flow_name, msisdn, session_id, input)
      flow_state = @state[flow_name.to_sym][session_key][:flow_state].to_sym
    rescue Exception => e
      logger.error "Exception: #{e.inspect} in #{e.backtrace[0]} when processing: flow: #{flow_name}, msisdn: #{msisdn}, session_id: #{session_id}, input: #{input}"
      logger.debug e.backtrace.inspect
      
      begin
        logger.debug 'Responding with default error message.'
        flow_for_messages = @flows[flow_name.to_sym]
        
        response = Colloquy::MessageBuilder.to_message(:error_unexpected, flow: flow_for_messages)
        flow_state = :notify
      rescue Exception => e
        logger.error 'An error occured when we tried to render the error message, falling back to default error response'
        logger.error "Exception: #{e.inspect} in #{e.backtrace[0]}"
        logger.debug e.backtrace.inspect
        
        response = DEFAULT_ERROR_MESSAGE
        flow_state = :notify
      end
    end
    
    # We construct a response object
    response = Colloquy::Response.new(response)
    response.flow_state = flow_state
    
    response
  end

  def reload_messages!
    @messages = {}

    load_messages
  end

  def reload_flows!
    @flows = {}

    load_flows
    load_messages
  end

  def reload_flow!(flow_name)
    @flows[flow_name.to_sym] = nil
    load_flow(flow_name)
    load_messages_into_flow(flow_name)
  end
  
  def flow_exists?(flow_name)
    @flows[flow_name.to_sym]
  end

  private

  # Checks all configurations including flows, logger and messages.
  # @return [true] if all are valid, raises an exception if not.
  def configuration_valid?
    @options[:path_config] = Colloquy.root.join('config')

    configuration_directory_exists?

    %W(flows logger messages).each do |file|
      method_name = "#{file}_yaml_exists?".to_sym
      send(method_name)

      key = "path_#{file}_yaml".to_sym
      @options[file.to_sym] = File.open(@options[key]) { |f| YAML.load(f.read) }
    end

    true
  end

  def configuration_directory_exists?
    unless File.exists?(Colloquy.root) and
        File.directory?(Colloquy.root) and
        File.directory?(@options[:path_config])
      raise Colloquy::ConfigurationFolderNotFound,
        "Cannot find #{Colloquy.root} to load configuration from.\
        Renderer needs a valid root path to read config/flows.yaml and config/logger.yaml"
    end
  end

  # Does lots of initial setup.
  # @private
  def configure
    initialize_logger
    
    load_paths
    load_flows
    load_messages
    
    set_maximum_message_length
    set_maximum_unicode_length
    set_flow_pool_size

    initialize_session
    initialize_state

    load_flow_pool
  end

  def flows_yaml_exists?
    @options[:path_flows_yaml] = @options[:path_config].join('flows.yaml')

    unless @options[:path_flows_yaml].exist?
      raise Colloquy::FlowConfigurationNotFound, "Cannot find flows yaml in #{@options[:path_flow_yaml]}"
    end
  end

  def logger_yaml_exists?
    @options[:path_logger_yaml] = @options[:path_config].join('logger.yaml')

    unless @options[:path_logger_yaml].exist?
      raise Colloquy::LoggerConfigurationNotFound, "Cannot find flows yaml in #{@options[:path_flow_yaml]}"
    end
  end
  
  def messages_yaml_exists?
    @options[:path_messages_yaml] = @options[:path_config].join('messages.yaml')
    
    unless @options[:path_messages_yaml].exist?
      raise Colloquy::MessagesConfigurationNotFound, "Cannot find messages yaml in #{@options[:path_messages_yaml]}"
    end
  end

  # Infer messages yaml path from flow name
  # @param [String] flow_name Flow name
  # @return [Pathname] Path to messages yaml corresponding to flow name
  def messages_file_name(flow_name)
    Colloquy.root.join('messages', "#{flow_name}.yaml")
  end

  # Configure and create logger instance
  def initialize_logger
    logger_file = Pathname.new(Colloquy.root.join(@options[:logger][:path]))
    log_level = if @options[:verbose]
        :DEBUG
      else
        @options[:logger][:log_level]
      end.upcase.to_sym

    raise Colloquy::LogDirectoryNotPresent unless logger_file

    @logger = Colloquy::Logger.new(logger_file)
    @logger.info 'Renderer starting up...'
    @logger.info "Log level is #{log_level}"
    @logger.level = ActiveSupport::Logger::Severity.const_get(log_level)
    
    # Set this up as a logger available at the root
    Colloquy.logger = @logger
  end

  # Load load_paths configured in flows yaml into ruby load path
  def load_paths
    @options[:flows][:load_paths].each do |path|
      flow_path = Pathname.new(path)
      $: << if flow_path.relative?
              Colloquy.root.join(flow_path)
            else
              flow_path
            end.realpath.to_s
    end
  end

  # Load all active flow specific messages into flow
  def load_messages
    @options[:flows][:active].each do |flow_entry|
      load_messages_into_flow(flow_entry)
    end
  end

  # Load flow specific messages into flow
  # @param [String] flow_entry Entry in flows yaml
  def load_messages_into_flow(flow_entry)
    flow_messages = @options[:messages]
    _, flow_name, _ = extract_flow_components_from_entry(flow_entry)
    
    if messages_file_name(flow_name).exist?    
      messages = File.open(messages_file_name(flow_name)) { |f| YAML.load(f.read) }
      messages ||= {}
      messages = messages.with_indifferent_access

      flow_messages = flow_messages.merge(messages)
    end
    
    @flows[flow_name.to_sym].messages = flow_messages
  end

  # Create a hash with all active flows mapped to their instances
  # @return [Hash] A Hash with all flows and instances
  def load_flows
    @flows = {}

    @options[:flows][:active].each do |flow_entry|
      load_flow(flow_entry)
    end

    @flows
  end

  def load_flow_pool
    @options[:flows][:active].each do |flow_entry|
      _, flow_name, flow_class = extract_flow_components_from_entry(flow_entry)
      messages = @flows[flow_name.to_sym].messages
      Colloquy::Renderer::FlowPool.create_flows(flow_name, flow_class, @flow_pool_size, logger: @logger, messages: messages)
    end
  end

  # Sets maximum messages length, restricted to 160 for by telecom Provider
  def set_maximum_message_length
    Colloquy.maximum_message_length = (@options[:flows][:maximum_message_length] || 160).to_i
  end

  # Sets maximum unicode length, restricted to 70 as unicode uses two bytes per character
  def set_maximum_unicode_length
    Colloquy.maximum_unicode_length = (@options[:flows][:maximum_unicode_length] || 70).to_i
  end

  def set_flow_pool_size
    @flow_pool_size = (@options[:flows][:flow_pool_size] || 50).to_i
  end

  # This is where the input is actually passed on to FlowParser#apply for processing.
  #
  # This method taps into flow object and injects the current state, session and headers
  # into it. This modifed object is then passed to FlowParser#apply
  # @return [Response] The response returned from FlowParser#apply
  def apply!(flow, state, session, session_key, flow_name, msisdn, session_id, input = nil)
    # set flow state and session correctly, reset all nodes    
    flow = prime_flow(flow, state, session, flow_name, msisdn, session_id, input)
    
    # apply and get the response
    response = flow.apply(input)

    # store the state and session from the applied flow
    state_reset_from_flow(flow, flow_name, session_key)
    session_reset_from_flow(flow, flow_name, session_key)

    # return the response
    response
  rescue Colloquy::SwitchFlowJump => e
    # add flow back into flow pool before switching to new flow
    Colloquy::Renderer::FlowPool.add_flow(flow.flow_name, flow)
    session_reset_from_flow(flow, flow_name, session_key)
    session_switch_flow(session_key, flow_name, e.payload[:flow], e.payload[:node])
    state, session, flow = state_load(flow_name, session_key)
    
    retry
  rescue Colloquy::FlowPoolEmpty
    flow = nil #explicitly marked as nil so that its not added back into the pool
    raise 
  ensure
    # add flow back into flow pool
    Colloquy::Renderer::FlowPool.add_flow(flow.flow_name, flow) if flow
  end
  
  def prime_flow(flow, state, session, flow_name, msisdn, session_id, input)
    flow.tap do |f|
      f.state = state
      f.session = session
      f.headers = {
          flow_name: flow_name,
          msisdn: msisdn,
          session_id: session_id,
          input: input,
          page: (state[:page] || 1),
          metadata: (state[:metadata] || {})
      }
    end
  end
  
  def state_reset_from_flow(flow, flow_name, session_key)
    @state[flow_name.to_sym][session_key] = flow.send(:state) # state is private
  end
  
  def session_reset_from_flow(flow, flow_name, session_key)
    @session[flow_name.to_sym][session_key] = flow.session
  end
  
  def is_flow?(flow)
    flow.is_a? Colloquy::FlowParser
  end
  
  def session_switch_flow(session_key, from, to, node_to = :index)
    from_flow = is_flow?(from) ? from : @flows[from] 
    to_flow = is_flow?(to) ? to : @flows[to]     
    node_to ||= :index

    unless is_flow?(to_flow)
      raise Colloquy::JumpInvalidException, "Cannot find flow #{to} to switch to"
    end

    current_state = @state[from_flow.flow_name][session_key]
    
    new_state = {
      :switched_from => current_state,
      :flow_name => to_flow.flow_name,
      :node => node_to,
      :flow_state => :init
    }

    # switch!
    @state[from_flow.flow_name][session_key] = new_state
  end

  #
  def state_load(flow_name, session_key, metadata = {})
    flow_name = flow_name.to_sym
    
    # extract the state if it's present
    flow_state = (@state[flow_name][session_key] || {})
    flow_session = (@session[flow_name][session_key] || {})
    
    # Now, load the flow_pool_key from the flow_state if set    
    flow_pool_key = (flow_state[:flow_name] || flow_name).to_sym
  
    # Pop a FlowParser object from flow pool
    flow = Colloquy::Renderer::FlowPool.pop_flow(flow_pool_key)
    raise Colloquy::FlowPoolEmpty, 'Flow pool is empty' unless flow

    # Merge in the metadata
    flow_state[:metadata] = metadata
    
    [flow_state, flow_session, flow]
  end

  # Load, instantiate and save that instance in an instance variable
  # @param [String, Hash] flow_entry Flow entry specified in flows yaml
  def load_flow(flow_entry)
    flow_path, flow_name, flow_class = extract_flow_components_from_entry(flow_entry)
    
    # we load the flow dynamically by the earlier set load_path
    require "#{flow_path}_flow"

    @flows[flow_name.to_sym] = flow_class.constantize.new(flow_name, logger: @logger)
  end

  # Extract path, name and class of flow using entry in flows yaml
  # @param [String, Hash] flow_entry Flow entry specified in flows yaml
  # @return [Array] Path, Name and Class of given flow
  def extract_flow_components_from_entry(flow_entry)
    if flow_entry.is_a? Hash
      flow_path = flow_entry.to_a.flatten.first
      flow_name = flow_path.split('/').last
      flow_class = flow_entry.to_a.flatten.last
    else
      flow_path = flow_entry
      flow_name = flow_entry.split('/').last
      flow_class = "#{flow_name}_flow".classify
    end
    
    [flow_path, flow_name, flow_class]
  end

  def initialize_session
    @session ||= {}

    @flows.each do |flow_name, flow|
      @session[flow_name.to_sym] ||= session_store
    end
  end

  def initialize_state
    @state ||= {}

    @flows.each do |flow_name, flow|
      @state[flow_name.to_sym] ||= state_store
    end
  end
  
  def session_store
    Colloquy::SessionStore.haystack(@options[:flows][:session_store] || :memory, :identifier => :sessions)
  end
  
  def state_store
    Colloquy::SessionStore.haystack(@options[:flows][:session_store] || :memory, :identifier => :state)
  end

  # @param [String, String] msisdn, session_id
  # @return [String] session_key
  def make_session_key(msisdn, session_id)
    "#{msisdn}-#{session_id}"
  end
end
