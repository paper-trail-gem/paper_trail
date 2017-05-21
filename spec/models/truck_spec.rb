require "rails_helper"

::RSpec.describe Truck, type: :model do
  it { is_expected.not_to be_versioned }
end
