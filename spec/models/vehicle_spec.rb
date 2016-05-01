require "rails_helper"

describe Vehicle, type: :model do
  it { is_expected.to_not be_versioned }
end
