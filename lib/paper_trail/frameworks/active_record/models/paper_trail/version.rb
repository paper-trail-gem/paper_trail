require "paper_trail/version_concern"

module PaperTrail
  # This is the default ActiveRecord model provided by PaperTrail. Most simple
  # applications will only use this and its partner, `VersionAssociation`, but
  # it is possible to sub-class, extend, or even do without this model entirely.
  # See the readme for details.
  class Version < ::ActiveRecord::Base
    include PaperTrail::VersionConcern

    # You can now get user object (supports Device defaults)
    def user(user_model = :User, primary_key = :id)
      unless whodunnit.nil?
      	user_model.to_s.constantize.find_by(primary_key.to_s, whodunnit)
      end
    end
  end
end
