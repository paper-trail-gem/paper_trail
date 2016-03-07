# Turn on associations tracking when the test suite is run on Travis CI
PaperTrail.config.track_associations = true if ENV["TRAVIS"]

module PaperTrail
  class Version < ActiveRecord::Base
    if ::PaperTrail.active_record_protected_attributes?
      attr_accessible :answer, :action, :question, :article_id, :ip, :user_agent, :title
    end
  end
end
