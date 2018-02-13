# frozen_string_literal: true

require "spec_helper"

module PaperTrail
  ::RSpec.describe ModelConfig do
    describe "when has_paper_trail is called" do
      it "raises an error" do
        expect {
          class MisconfiguredCVC < ActiveRecord::Base
            has_paper_trail class_name: "AbstractVersion"
          end
        }.to raise_error(
          /use concrete \(not abstract\) version models/
        )
      end
    end
  end
end
