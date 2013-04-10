require 'rubygems'
require 'bundler/setup'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../dummy/config/environment', __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

require 'rails'
require 'active_record'

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.order = 'random'
end

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

ActiveRecord::Schema.define(:version => 1) do
  create_table :models do |t|
    t.string :name
    t.string :color
  end
  create_table :versions do |t|
    t.string   :item_type, null: false
    t.string   :item_id,   null: false
    t.string   :event,     null: false
    t.string   :whodunnit
    t.text     :object
    t.datetime :created_at
  end
end

class Model < ActiveRecord::Base
  has_paper_trail
  attr_accessible :name, :color
end
