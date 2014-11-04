if RUBY_VERSION < "1.9.2"
  require 'delorean'

  class Timecop
    def self.travel(t)
      Delorean.time_travel_to t
    end

    def self.return
      Delorean.back_to_the_present
    end
  end
else
  require 'timecop'
end