class ProtectedWidget < Widget
  attr_accessible :name, :a_text if respond_to?(:attr_accessible)
end
