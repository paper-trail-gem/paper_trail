module PaperTrail
  class Config
    include Singleton
    attr_accessor :enabled, :timestamp_field
 
    def initialize
      # Indicates whether PaperTrail is on or off.
      @enabled         = true
      @timestamp_field = :created_at
    end
  end
end
