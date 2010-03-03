require 'yaml'
require 'paper_trail/has_paper_trail'
require 'paper_trail/version'

module PaperTrail
  
  def self.included(base)
    base.before_filter :set_whodunnit
  end

  def self.whodunnit
    Thread.current[:whodunnit]
  end

  private
  def set_whodunnit
    Thread.current[:whodunnit] = self.send :current_user rescue nil
  end
end

ActionController::Base.send :include, PaperTrail
