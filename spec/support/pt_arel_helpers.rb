# frozen_string_literal: true

module PTArelHelpers
  def arel_value(node)
    if node.respond_to?(:val) # rails < 6.1
      node.val
    else
      node.value
    end
  end
end
