# frozen_string_literal: true

class Song < ActiveRecord::Base
  has_paper_trail
  attribute :name, :string

  # Uses an integer of seconds to hold the length of the song
  def length=(minutes)
    write_attribute(:length, minutes.to_i * 60)
  end

  def length
    read_attribute(:length) / 60
  end
end
