module PaperTrail
  module VERSION
    MAJOR = 4
    MINOR = 1
    TINY  = 0
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
