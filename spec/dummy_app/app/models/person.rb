# frozen_string_literal: true

class Person < ApplicationRecord
  has_many :authorships, foreign_key: :author_id, dependent: :destroy
  has_many :books, through: :authorships

  has_many :pets, foreign_key: :owner_id, dependent: :destroy
  has_many :animals, through: :pets
  has_many :dogs, class_name: "Dog", through: :pets, source: :animal
  has_many :cats, class_name: "Cat", through: :pets, source: :animal

  has_one :car, foreign_key: :owner_id
  has_one :bicycle, foreign_key: :owner_id

  has_one :thing

  belongs_to :mentor, class_name: "Person", optional: true

  has_paper_trail

  # Convert strings to TimeZone objects when assigned
  def time_zone=(value)
    if value.is_a? ActiveSupport::TimeZone
      super
    else
      zone = ::Time.find_zone(value) # nil if can't find time zone
      super(zone)
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

    delegate :dump, to: :class

    delegate :load, to: :class
  end

  # Rails 7.1 deprecates positional argument for coder
  if Rails.gem_version >= Gem::Version.new("7.1")
    serialize :time_zone, coder: TimeZoneSerializer.new
  else
    serialize :time_zone, TimeZoneSerializer.new
  end
end
