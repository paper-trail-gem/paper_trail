# frozen_string_literal: true

# This custom serializer excludes nil values
class CustomObjectChangesAdapter
  def diff(changes)
    changes
  end

  def load_changeset(version)
    version.changeset
  end

  def where_object_changes(klass, attributes)
    klass.where(attributes)
  end
end
