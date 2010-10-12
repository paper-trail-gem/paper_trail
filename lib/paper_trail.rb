require 'singleton'
require 'yaml'

require 'action_controller'
require 'active_record'

require 'paper_trail/config'
require 'paper_trail/controller'
require 'paper_trail/has_paper_trail'
require 'paper_trail/version'


# PaperTrail's module methods can be called in both models and controllers.
module PaperTrail

  # Switches PaperTrail on or off.
  def self.enabled=(value)
    PaperTrail.config.enabled = value
  end

  # Returns `true` if PaperTrail is on, `false` otherwise.
  # PaperTrail is enabled by default.
  def self.enabled?
    !!PaperTrail.config.enabled
  end


  # Returns who is reponsible for any changes that occur.
  def self.whodunnit
    paper_trail_store[:whodunnit]
  end

  # Sets who is responsible for any changes that occur.
  # You would normally use this in a migration or on the console,
  # when working with models directly.  In a controller it is set
  # automatically to the `current_user`.
  def self.whodunnit=(value)
    paper_trail_store[:whodunnit] = value
  end

  # Returns any information from the controller that you want
  # PaperTrail to store.
  #
  # See `PaperTrail::Controller#info_for_paper_trail`.
  def self.controller_info
    paper_trail_store[:controller_info]
  end

  # Sets any information from the controller that you want PaperTrail
  # to store.  By default this is set automatically by a before filter.
  def self.controller_info=(value)
    paper_trail_store[:controller_info] = value
  end


  private

  # Thread-safe hash to hold PaperTrail's data.
  def self.paper_trail_store
    Thread.current[:paper_trail] ||= {}
  end

  # Returns PaperTrail's configuration object.
  def self.config
    @@config ||= PaperTrail::Config.instance
  end

end
