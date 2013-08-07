class ProtectedWidget < Widget
  attr_accessible :name, :a_text if ::PaperTrail.active_record_protected_attributes?
end
