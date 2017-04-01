module OverrideSongAttributesTheRails4Way
  def attributes
    if name
      super.merge(name: name)
    else
      super
    end
  end

  def changed_attributes
    if name
      super.merge(name: name)
    else
      super
    end
  end
end

class Song < ActiveRecord::Base
  has_paper_trail

  # Uses an integer of seconds to hold the length of the song
  def length=(minutes)
    write_attribute(:length, minutes.to_i * 60)
  end

  def length
    read_attribute(:length) / 60
  end

  if ActiveRecord::VERSION::MAJOR >= 5
    attribute :name, :string
  else
    attr_accessor :name
    prepend OverrideSongAttributesTheRails4Way
  end
end
