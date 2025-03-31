# frozen_string_literal: true

require "spec_helper"

RSpec.describe Vehicle do
  it { is_expected.not_to be_versioned }
end
