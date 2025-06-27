# frozen_string_literal: true

class CarWithLockVersion < Car
  attribute :lock_version, :integer, default: 0
end
