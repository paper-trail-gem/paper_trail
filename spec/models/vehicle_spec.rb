# frozen_string_literal: true

require "spec_helper"

RSpec.describe Vehicle, type: :model do
  it { is_expected.not_to be_versioned }
end
