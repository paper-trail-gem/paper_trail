module PaperTrail
  module Controller

    def self.included(base)
      base.before_filter :set_paper_trail_enabled_for_controller
      base.before_filter :set_paper_trail_whodunnit, :set_paper_trail_controller_info
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

    # Returns any information about the controller or request that you
    # want PaperTrail to store alongside any changes that occur.  By
    # default this returns an empty hash.
    #
    # Override this method in your controller to return a hash of any
    # information you need.  The hash's keys must correspond to columns
    # in your `versions` table, so don't forget to add any new columns
    # you need.
    #
    # For example:
    #
    #     {:ip => request.remote_ip, :user_agent => request.user_agent}
    #
    # The columns `ip` and `user_agent` must exist in your `versions` # table.
    #
    # Use the `:meta` option to `PaperTrail::Model::ClassMethods.has_paper_trail`
    # to store any extra model-level data you need.
    def info_for_paper_trail
      {}
    end

    # Returns `true` (default) or `false` depending on whether PaperTrail should
    # be active for the current request.
    #
    # Override this method in your controller to specify when PaperTrail should
    # be off.
    def paper_trail_enabled_for_controller
      true
    end

    private

    # Tells PaperTrail whether versions should be saved in the current request.
    def set_paper_trail_enabled_for_controller
      ::PaperTrail.enabled_for_controller = paper_trail_enabled_for_controller
    end

    # Tells PaperTrail who is responsible for any changes that occur.
    def set_paper_trail_whodunnit
      ::PaperTrail.whodunnit = user_for_paper_trail if paper_trail_enabled_for_controller
    end

    # DEPRECATED: please use `set_paper_trail_whodunnit` instead.
    def set_whodunnit
      logger.warn '[PaperTrail]: the `set_whodunnit` controller method has been deprecated.  Please rename to `set_paper_trail_whodunnit`.'
      set_paper_trail_whodunnit
    end

    # Tells PaperTrail any information from the controller you want
    # to store alongside any changes that occur.
    def set_paper_trail_controller_info
      ::PaperTrail.controller_info = info_for_paper_trail if paper_trail_enabled_for_controller
    end

  end
end
