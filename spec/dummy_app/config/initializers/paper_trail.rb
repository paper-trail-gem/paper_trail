# frozen_string_literal: true

::ActiveSupport::Deprecation.silence do
  ::PaperTrail.config.track_associations = true
end
