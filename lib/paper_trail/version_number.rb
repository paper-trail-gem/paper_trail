module PaperTrail
  # :nodoc:
  module VERSION
    MAJOR = 6
    MINOR = 0
    TINY = 1
    PRE = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".").freeze

    def self.to_s
      STRING
    end
  end
end
