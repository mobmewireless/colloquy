
class SettingsFlow
  include Colloquy::FlowParser

  index {
    request {
      prompt "Reply 1 to know today's date"
    }

    process { |input|
      if input.to_i == 1
        notify Time.now.to_s
      else
        notify "Wrong input"
      end
    }
  }

  def config
    #settings[:testing] returns the yaml parsed hash loaded from the file, defined corresponding to testing key in settings.yaml
    settings[:testing]
  end
end
