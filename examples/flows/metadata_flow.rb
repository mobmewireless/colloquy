
class MetadataFlow
  include Colloquy::FlowParser
  
  index {
    request { |input|
      logger.info "Metadata: #{headers[:metadata].inspect}"
      notify "I love #{headers[:metadata][:love]}"
    }
  }
end
