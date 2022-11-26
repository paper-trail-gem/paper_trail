# frozen_string_literal: true

class Skipper < ApplicationRecord
  has_paper_trail ignore: [:created_at], skip: [:another_timestamp]
end
