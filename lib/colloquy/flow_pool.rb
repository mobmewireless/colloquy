class Colloquy::Renderer::FlowPool

  def self.create_flows(flow_name, flow_class, pool_size, options)
    pool_size.times do |i|
      flow_pool[flow_name.to_sym] << flow_class.constantize.new(flow_name, options)
    end
  end

  def self.flow_pool
    @flow_pool ||= Hash.new { |hash, key| hash[key] = [] } 
  end

  def self.pop_flow(flow_name)
    @flow_pool[flow_name.to_sym].pop
  end

  def self.add_flow(flow_name, flow)
    @flow_pool[flow_name.to_sym] << flow
  end
end

