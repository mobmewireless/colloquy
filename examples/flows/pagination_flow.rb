
class PaginationFlow

  include Colloquy::FlowParser
  
  index {
    request {
      menu.prefix { 
        if headers[:page] == 1
          "Welcome to Some new application. Please choose from one of the packs below to get latest news from Some new application" 
        end
      }
      1.upto(10).each do |item|
        menu << "Pack #{item}"
      end
    }
    
    process { |input|

    }
  }
end

