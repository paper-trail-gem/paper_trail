# frozen_string_literal: true

module PrefixVersionsInspectWithCount
  def inspect
    "#{length} versions:\n" +
      super
  end
end
