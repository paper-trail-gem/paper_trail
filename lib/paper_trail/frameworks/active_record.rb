# frozen_string_literal: true

# Either ActiveRecord has already been loaded by the Lazy Load Hook in our
# Railtie, or else we load it now.
require "active_record"
::PaperTrail::Compatibility.check_activerecord(::ActiveRecord.gem_version)

# Now we can load the parts of PT that depend on AR.
require "paper_trail/has_paper_trail"
require "paper_trail/reifier"
require "paper_trail/frameworks/active_record/models/paper_trail/version"
ActiveRecord::Base.include PaperTrail::Model
