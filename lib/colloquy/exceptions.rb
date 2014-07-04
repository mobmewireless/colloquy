class Colloquy::JumpException < Exception
  attr_accessor :payload
end

class Colloquy::NotifyJump < Colloquy::JumpException
end

class Colloquy::SwitchJump < Colloquy::JumpException
end

class Colloquy::SwitchBackJump <  Colloquy::JumpException
end

class Colloquy::SwitchFlowJump < Colloquy::JumpException
end

class Colloquy::PassJump < Colloquy::JumpException
end

class Colloquy::IndexNodeNotFoundException < Exception
end

class Colloquy::NodeNotFoundException < Exception
end

class Colloquy::DuplicateNodeException < Exception
end

class Colloquy::ConfigurationFolderNotFound < Exception
end

class Colloquy::FlowConfigurationNotFound < Exception
end

class Colloquy::LoggerConfigurationNotFound < Exception
end

class Colloquy::MessagesConfigurationNotFound < Exception
end

class Colloquy::FlowNotFound < Exception
end

class Colloquy::FlowStateInconsistent < Exception
end

class Colloquy::MSISDNParameterEmpty < Exception
end

class Colloquy::SessionIDParameterEmpty < Exception
end

class Colloquy::InputParameterEmpty < Exception
end

class Colloquy::JumpInvalidException < Exception
end

class Colloquy::FlowPoolEmpty < Exception
end

class Colloquy::LogDirectoryNotPresent < Exception
end

