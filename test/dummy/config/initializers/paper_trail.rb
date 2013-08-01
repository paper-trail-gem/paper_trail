module PaperTrail
  class Version < ActiveRecord::Base
    attr_accessible :created_at, :updated_at, :answer, :action, :question, :article_id, :ip, :user_agent, :title if respond_to?(:attr_accessible)
  end
end
