# frozen_string_literal: true

class Planet < ApplicationRecord
  has_paper_trail versions: { class_name: "PlanetVersion" }
end
