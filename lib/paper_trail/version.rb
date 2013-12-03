require File.expand_path('../version_concern', __FILE__)

module PaperTrail
  class Version < ::ActiveRecord::Base
    include PaperTrail::VersionConcern
  end
end
