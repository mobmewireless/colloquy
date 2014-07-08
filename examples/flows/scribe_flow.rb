
class ScribeFlow
  include MobME::Infrastructure::USSDRendererRedux::FlowParser

  index {
    request {
      #Available methods are standard methods of scribe gem, like log_visit, log_event etc.
      #You may inspect the available methods as in the case of any other object.
      scriber.log_visit({:mobile => headers[:msisdn], :uri => headers[:input]})
      prompt "Please type a 5 letter palindrome word"
    }

    process { |input|
      if input.length == 5 && input == input.reverse
        notify "Congrats. #{input} is a palindrome."
      else
        notify "I dont think #{input} is a palindrome."
      end
    }
  }

  def scriber
    #The below scribe object is a singleton object, hence each call will return the same object only.
    scribe[:testing]
  end
end
