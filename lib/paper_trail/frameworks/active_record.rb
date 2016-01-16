# This file only needs to be loaded if the gem is being used outside of Rails,
# since otherwise the model(s) will be configured for autoloading by
# `PaperTrail::Rails::Engine`.
require "paper_trail/frameworks/active_record/models/paper_trail/version_association"
require "paper_trail/frameworks/active_record/models/paper_trail/version"

# Likewise, in rails, the inclusion of `PaperTrail::Model` into `ActiveRecord`
# would be done by `PaperTrail::Rails::Engine`.
ActiveSupport.on_load(:active_record) do
  include PaperTrail::Model
end
