class Person < ActiveRecord::Base
  has_many :authorships, :dependent => :destroy
  has_many :books, :through => :authorships
  has_paper_trail

  # Convert strings to TimeZone objects when assigned
  def time_zone=(value)
    if value.is_a? ActiveSupport::TimeZone
      super
    else
      zone = ::Time.find_zone(value)  # nil if can't find time zone
      super zone
    end
  end

  # Store TimeZone objects as strings when serialized to database
  class TimeZoneSerializer
    def dump(zone)
      zone.try(:name)
    end
   
    def load(value)
      ::Time.find_zone!(value) rescue nil
    end
  end
 
  serialize :time_zone, TimeZoneSerializer.new
end
