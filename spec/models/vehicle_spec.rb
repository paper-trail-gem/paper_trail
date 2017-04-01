require "rails_helper"

describe Vehicle, type: :model do
  it { is_expected.not_to be_versioned }
end
