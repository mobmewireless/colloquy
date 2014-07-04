
class ArtOfWarFlow
  include Colloquy::FlowParser
  
  index {
    request {
      session[:hello] = "yellow!"
      menu.push(
        :calculator, # to test a swtich
        :special_redis,
        :estimates, :waging_war, :offensive_strategy, :dispositions, :energy, 
        :weaknesses_and_strengths, :manoeuvre, :nine_variables, :marches, 
        :terrain, :the_nine_varieties_of_ground, :attack_by_fire, 
        :employment_of_secret_agents
      )
    }
    
    process { |input|
      session[:hello] = "world"
      switch :index, :flow => :calculator if menu.key(input) == :calculator
      switch :index, :flow => :special_redis if menu.key(input) == :special_redis
      switch :index, :flow => :unknown if menu.key(input) == :offensive_strategy

      notify "#{menu.key(input)}_notification".to_sym
    }
  }
end
