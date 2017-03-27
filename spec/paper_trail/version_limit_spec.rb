require 'rails_helper'

module PaperTrail
  RSpec.describe Cleaner, versioning: true do
    before do
      @last_limit = PaperTrail.config.version_limit
    end
    after do
      PaperTrail.config.version_limit = @last_limit
    end

    it 'cleans up old versions' do
      PaperTrail.config.version_limit = 10
      widget = Widget.create

      100.times do |i|
        widget.update_attributes(name: "Name #{i}")
        expect(Widget.find(widget.id).versions.count).to be <= 11
        # 11 versions = 10 updates + 1 create.
      end
    end
  end
end
