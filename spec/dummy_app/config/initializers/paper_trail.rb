# frozen_string_literal: true

::ActiveSupport::Deprecation.silence do
  ::PaperTrail.config.track_associations = true
  ::PaperTrail.config.i_have_updated_my_existing_item_types = true
end
