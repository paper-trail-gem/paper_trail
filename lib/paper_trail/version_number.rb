module PaperTrail
  # :nodoc:
  module VERSION
    MAJOR = 5
    MINOR = 2
    TINY = 3
    PRE = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".").freeze

    def self.to_s
      STRING
    end
  end
end
