module PaperTrail
  module VERSION
    MAJOR = 3
    MINOR = 0
    TINY  = 7
    PRE   = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')

    def self.to_s
      STRING
    end
  end

  def self.version
    VERSION::STRING
  end
end
