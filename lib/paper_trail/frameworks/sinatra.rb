module Sinatra
  module PaperTrail

    # Register this module inside your Sinatra application to gain access to controller-level methods used by PaperTrail
    def self.registered(app)
      app.helpers Sinatra::PaperTrail
      app.before { set_paper_trail_whodunnit }
    end

    protected

    # Returns the user who is responsible for any changes that occur.
    # By default this calls `current_user` and returns the result.
    #
    # Override this method in your controller to call a different
    # method, e.g. `current_person`, or anything you like.
    def user_for_paper_trail
      current_user if defined?(current_user)
    end

    private

    # Tells PaperTrail who is responsible for any changes that occur.
    def set_paper_trail_whodunnit
      ::PaperTrail.whodunnit = user_for_paper_trail if ::PaperTrail.enabled?
    end

  end

  register Sinatra::PaperTrail if defined?(register)
end
