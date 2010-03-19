module PaperTrail
  class Config
    include Singleton
    attr_accessor :enabled
 
    def initialize
      # Indicates whether PaperTrail is on or off.
      @enabled = true
    end
  end
end
