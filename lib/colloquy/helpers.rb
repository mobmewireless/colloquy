
module Colloquy::Helpers
    require_relative 'helpers/url'
    require_relative 'helpers/mysql'
    require_relative 'helpers/redis'
    require_relative 'helpers/scribe'
    require_relative 'helpers/settings'
    
    include Colloquy::Helpers::Url
    include Colloquy::Helpers::MySQL
    include Colloquy::Helpers::Redis
    include Colloquy::Helpers::Scribe
    include Colloquy::Helpers::Settings
end
  
