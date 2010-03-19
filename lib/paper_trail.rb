require 'yaml'
require 'paper_trail/config'
require 'paper_trail/has_paper_trail'
require 'paper_trail/version'

module PaperTrail

  def self.included(base)
    base.before_filter :set_whodunnit
  end

  # Returns PaperTrail's configuration object.
  def self.config
    @@config ||= PaperTrail::Config.instance
  end

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
    Thread.current[:whodunnit]
  end

  # Sets who is responsible for any changes that occur.
  # You would normally use this in a migration or on the console,
  # when working with models directly.  In a controller it is set
  # automatically to the `current_user`.
  def self.whodunnit=(value)
    Thread.current[:whodunnit] = value
  end

  protected

  # Sets who is responsible for any changes that occur: the controller's
  # `current_user`.
  def set_whodunnit
    Thread.current[:whodunnit] = self.send :current_user rescue nil
  end
end

ActionController::Base.send :include, PaperTrail
