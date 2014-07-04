require 'url-agent'

module Colloquy::Helpers::Url
  def url
    url_agent = URLAgent::Base.instance
    url_agent.configure(:path_root => Colloquy.root)
    
    url_agent
  end
end
