require 'random_word_generator'
require 'active_support/inflector'

class HangmanFlow

  include Colloquy::FlowParser
  NUMBER_CRYPTEX = "22233344455566677778889999"
  
  index {
    request {       
      prompt "Hangman..Ready to die? No escape now!\n" + 
             "Enter any key to start."
    }
    
    process { |input|
      session[:secret] = RandomWordGenerator.word
      session[:lives] = 9
      session[:used_letters] = "0"
      session[:message] = ""
      
      switch :game_logic
    }
  }
  
  game_logic {
    request {
      notify "#{session[:secret]}\n You WIN!" if session[:secret] == word_with_user_input
      notify "You LOSE. The word was #{session[:secret]}" if session[:lives] == 0

      prompt "#{session[:message]}\n     #{word_with_user_input}    \n" + 
             "You have #{session[:lives]} #{pluralize(session[:lives], 'life')} left.\n" + 
             "Enter letter (A=>2,B=>22,C=>222,D=>3). Enter 0 to quit."
    }
    
    process { |input|
      notify "Exiting application.." if input == "0"
      
      if valid_input? input
        letter_entered = translate_letter_code(input)
        if session[:used_letters].include? letter_entered 
           session[:message] = "You already entered this letter."           
        else
          session[:used_letters] << letter_entered
          if session[:secret].include? letter_entered
             session[:message] = "You entered #{letter_entered}. Aha! Good guess."
          else
             session[:lives] -= 1
             session[:message] = "You entered #{letter_entered}. Bad luck!"
          end
        end
      else
         session[:message] = "Invalid letter code."
      end
      switch :game_logic
    }
  }


  def valid_input?(number)
    if  number.length <= 4 && ["7","9"].include?(number.squeeze)
      return true
    elsif number.length <= 3 && ["2","3","4","5","6","8"].include?(number.squeeze)
      return true
    else 
      return false
    end
  end
  
  def translate_letter_code(letter_code)
    ("a".."z").to_a[NUMBER_CRYPTEX.index(letter_code) + letter_code.length - 1]
  end
  
  def word_with_user_input
    regex = Regexp.new("[^#{session[:used_letters]}]")
    session[:secret].gsub(regex,'-')
  end
  
  def pluralize(number, text)
    return text.pluralize if number != 1
    text
  end
end
