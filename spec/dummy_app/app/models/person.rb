class Person < ActiveRecord::Base
  has_many :authorships, foreign_key: :author_id, dependent: :destroy
  has_many :books, through: :authorships
  belongs_to :mentor, class_name: "Person", foreign_key: :mentor_id
  has_paper_trail

  # Convert strings to TimeZone objects when assigned
  def time_zone=(value)
    if value.is_a? ActiveSupport::TimeZone
      super
    else
      zone = ::Time.find_zone(value) # nil if can't find time zone
      super zone
    end
  end

  # Store TimeZone objects as strings when serialized to database
  class TimeZoneSerializer
    class << self
      def dump(zone)
        zone.try(:name)
      end

      def load(value)
        ::Time.find_zone(value)
      end
    end

    def dump(zone)
      self.class.dump(zone)
    end

    def load(value)
      self.class.load(value)
    end
  end

  serialize :time_zone, TimeZoneSerializer.new
end
