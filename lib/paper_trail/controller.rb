module PaperTrail
  module Controller

    def self.included(base)
      base.before_filter :set_whodunnit
    end

    protected

    # Sets who is responsible for any changes that occur: the controller's
    # `current_user`.
    def set_whodunnit
      ::PaperTrail.whodunnit = self.send :current_user rescue nil
    end

  end
end

ActionController::Base.send :include, PaperTrail::Controller
