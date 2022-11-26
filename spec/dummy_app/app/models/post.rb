# frozen_string_literal: true

class Post < ApplicationRecord
  has_paper_trail versions: { class_name: "PostVersion" }
end
