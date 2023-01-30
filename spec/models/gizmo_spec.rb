# frozen_string_literal: true

require "spec_helper"
require "support/performance_helpers"

RSpec.describe Gizmo, type: :model, versioning: true do
  context "with a persisted record" do
    it "does not use the gizmo `updated_at` as the version's `created_at`" do
      gizmo = described_class.create(name: "Fred", created_at: Time.current - 1.day)
      gizmo.name = "Allen"
      gizmo.save(touch: false)
      expect(gizmo.versions.last.created_at).not_to(eq(gizmo.updated_at))
    end
  end
end
