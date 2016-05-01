PaperTrail.config.track_associations = true

module PaperTrail
  class Version < ActiveRecord::Base
    if ::PaperTrail.active_record_protected_attributes?
      attr_accessible :answer, :action, :question, :article_id, :ip, :user_agent, :title
    end
  end
end
