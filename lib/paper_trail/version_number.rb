module PaperTrail
  module VERSION
    MAJOR = 5
    MINOR = 0
    TINY = 0
    PRE = "pre".freeze

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".").freeze

    def self.to_s
      STRING
    end
  end
end
