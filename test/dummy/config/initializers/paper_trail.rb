module PaperTrail
  class Version < ActiveRecord::Base
    attr_accessible :answer, :action, :question, :article_id, :ip, :user_agent, :title if ::PaperTrail.active_record_protected_attributes?
  end
end
