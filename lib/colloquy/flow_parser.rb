
require_relative 'helpers'
require 'active_support/core_ext/hash/indifferent_access'

module Colloquy::FlowParser
  def self.included(klass)
    klass.class_eval do
      include InstanceMethods
      extend ClassMethods
    end
  end
  
  module InstanceMethods
    STATE_DEFAULT = { node: :index, flow_state: :init, previous: {} }
    
    include Colloquy::Helpers
    
    attr_accessor :nodes
    attr_accessor :logger, :session, :messages, :headers
    
    # Initializes the flow
    # @param [Hash] options A list of options passed on to the flow.
    def initialize(flow_name = nil, options = {})
      @flow_name = flow_name.to_sym if flow_name
      @logger = options[:logger] || Logger.new(STDOUT)
      @session = HashWithIndifferentAccess.new(options[:session] || {})
      @messages = options[:messages] || {}
      @headers = {}
      
      self.state = options[:state]
      @nodes = options[:nodes] || []
      
      setup if self.class.method_defined?(:setup)
      
      create_nodes_from_definitions! if @nodes.empty?
    end
    
    def flow_name
      @flow_name ||= "#{self.class}".underscore.gsub(/_flow/, '').split('/').last.to_sym
    end

    # Do not set @state directly, because it has many checks to ensure that @state is never inconsistent
    def state=(state)
      @state = STATE_DEFAULT.merge(flow_name: flow_name).merge(state || {})
    end
    
    def node_add(identifier, options = {}, &payload)
      if node_by_id(identifier)
        raise Colloquy::DuplicateNodeException, "A node named #{identifier} is already present in the flow"
      end
      
      options.merge!(flow: self)
      
      @nodes << Colloquy::Node.new(identifier, options, &payload)
    end
    
    def apply(input = nil)
      reset_nodes!
      input = sanitize_input(input)
      
      store_previous_state!
      
      case state[:flow_state].to_sym
      when :init
        store_back_state!
        
        apply_request(input)
      when :request
        apply_process(input)
      else
        raise Colloquy::FlowStateInconsistent, "An unexpected flow state: #{state[:flow_state]} was found"
      end
    rescue Colloquy::NotifyJump => e
      notify! e.payload
    rescue Colloquy::SwitchJump => e
      switch! e.payload
    rescue Colloquy::SwitchBackJump => e
      switch_back!
    rescue Colloquy::PassJump => e
      pass! input
    end
    
    def reset!(include_messages = false)
      @session = HashWithIndifferentAccess.new
      @state = {}
      self.state = {}
      @headers = {}

      @messages = {} if include_messages
      
      reset_nodes!
    end

    def reset_nodes!
      @nodes.each do |node|
        node.reset!
      end
    end
    
    def _(message_emergent)      
      Colloquy::MessageBuilder.to_message(message_emergent, :flow => self)
    end
    
    def notify(message)
      raise_jump_exception(Colloquy::NotifyJump, message)
    end

    def switch(node, options = {})
      if node == :back
        raise_jump_exception(Colloquy::SwitchBackJump)
      end
  
      if options[:flow]
        raise_jump_exception(Colloquy::SwitchFlowJump, { :node => node, :flow => options[:flow] })
      end
      
      raise_jump_exception(Colloquy::SwitchJump, node)
    end

    def pass
      raise_jump_exception(Colloquy::PassJump)
    end

    private
    def raise_jump_exception(type, payload = nil)
      jump_exception = type.new
      jump_exception.payload = payload
      raise jump_exception
    end
    
    def notify!(message)
      state.merge!(flow_state: :notify)
      Colloquy::MessageBuilder.to_message(message, messages: messages)
    end
    
    def switch!(node)
      state.merge!(:node => node.to_sym, :flow_state => :init, :switched_from => state.dup)
      apply
    end

    def switch_back!
      if state[:back][:flow_name].to_sym != state[:flow_name].to_sym
        raise_jump_exception(Colloquy::SwitchFlowJump, { :node => state[:back][:node], :flow => state[:back][:flow_name].to_sym })
      end

      if state[:back][:flow_name] == state[:flow_name] and state[:back][:node] == state[:node]
        raise Colloquy::JumpInvalidException, "No previous switch found to jump back to"
      end

      state.merge!(:node => state[:back][:node], :flow_state => :init)
      apply
    end
    
    def pass!(input)
      unless state[:flow_state] == :request
        raise Colloquy::JumpInvalidException, "The instruction pass can only be called from within the request block"
      end
      
      # This is a direct initial input
      input.direct = true
            
      apply(input)
    end
    
    def state
      @state
    end
    
    def create_nodes_from_definitions!
      @nodes = []
      
      return unless self.class.node_definitions
      
      self.class.node_definitions.each do |node_definition|
        node_add(node_definition[:identifier], node_definition[:options], &node_definition[:payload])
      end
    end

    def store_back_state!
      state[:back] = {
          node: state[:previous][:node],
          flow_name: state[:previous][:flow_name]
      } 
    end
    
    def store_previous_state!
      state_actual = state[:switched_from] || state
      state[:previous] = state_actual.except(:previous, :switched_from, :back)
      
      state.delete(:switched_from)
    end
    
    def state_delete_supplements!
      state.delete(:menu)
      state.delete(:page)
      state.delete(:prompt)
    end
    
    def apply_request(input)
      state[:flow_state] = :request
      
      current_node = node_by_id(state[:node])
      apply_node_not_found_exception unless current_node

      current_node.request!(input)
      
      # let's find the prompt if the request chain goes through without any jumps
      output = current_node.render
      
      # and store it in the state (we might use it later in the flow)
      store_state_from_node(current_node)
      
      output
    end
    
    def apply_process(input)
      previous_menu = generate_previous_menu
      previous_prompt = generate_previous_prompt
      
      if previous_prompt && (previous_prompt.key(input) == :more) && (previous_prompt.total_pages > previous_prompt.page)
        state[:page] = state[:previous][:page] + 1
        state[:prompt] = state[:previous][:prompt]
        
        headers[:page] = state[:page]
        previous_prompt.page = state[:page]
        previous_prompt.render
      elsif previous_menu && (previous_menu.key(input) == :more) && (previous_menu.total_pages > previous_menu.page)
        state[:page] = state[:previous][:page] + 1
        state[:menu] = state[:previous][:menu]
      
        headers[:page] = state[:page]
        previous_menu.page = state[:page]
        previous_menu.render
      elsif previous_menu && (previous_menu.key(input) == :previous) && (previous_menu.page > 1)
        state[:page] = state[:previous][:page] - 1
        state[:menu] = state[:previous][:menu]
      
        headers[:page] = state[:page]
        previous_menu.page = state[:page]
        previous_menu.render
      else
        state[:flow_state] = :process
        state_delete_supplements!
        
        current_node = node_by_id(state[:node])
        apply_node_not_found_exception(:process) unless current_node
      
        current_node.instance_variable_set(:@menu, previous_menu)
        current_node.instance_variable_set(:@prompt, previous_prompt)
        current_node.process!(input)
      end
    end
    
    def store_state_from_node(node)
      state[:menu] = { :pages => node.menu.pages } if node.menu?
      state[:prompt] = node.instance_variable_get(:@prompt).pages if node.prompt?
      state[:page] = 1
    end
    
    def generate_previous_menu
      return false unless state[:previous][:menu]
      
      menu = node_by_id(state[:node]).menu
      menu.page = state[:page]
      menu.pages = state[:previous][:menu][:pages]
            
      menu.freeze
      menu
    end
    
    def generate_previous_prompt
      return false unless state[:previous][:prompt]
      
      prompt = Colloquy::Prompt.new(flow: self, page: state[:previous][:page])
      prompt.page = state[:page]
      prompt.pages = state[:previous][:prompt]
      prompt.freeze
      
      prompt
    end
    
    def apply_node_not_found_exception(from = :request)
      if state[:node] == :index and from == :request 
        raise Colloquy::IndexNodeNotFoundException
      else
        raise Colloquy::NodeNotFoundException, "The node #{state[:node]} was not found in the #{from} state."
      end
    end

    def node_by_id(identifier)
      @nodes.find { |node| node.identifier == identifier.to_sym }
    end

    def sanitize_input(input)
      Colloquy::Input.new(input)
    end
  end

  module ClassMethods
    attr_accessor :node_definitions

    def method_missing(method, *arguments, &block)
      @node_definitions ||= []

      identifier = method
      options = arguments.first || {}
      payload = block

      @node_definitions << { :identifier => method, :options => options, :payload => payload }
    end
    
    private
    def to_ary; end
  end
end
