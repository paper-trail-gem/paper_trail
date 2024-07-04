# frozen_string_literal: true

require "spec_helper"

RSpec.describe Planet, type: :model do
  let!(:user) { User.create!(name: FFaker::Name.name) }

  def create_and_update_planet
    PaperTrail.request(whodunnit: user) do
      planet = PaperTrail.request(whodunnit: nil) do
        Planet.create!(name: "The Earth")
      end
      planet.update!(name: "Earth")
    end
  end

  it { expect { create_and_update_planet }.not_to change(User, :count).from(1) }
end
