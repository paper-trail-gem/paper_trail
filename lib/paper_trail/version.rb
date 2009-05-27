class Version < ActiveRecord::Base
  belongs_to :item, :polymorphic => true
  validates_presence_of :event

  def reify
    unless object.nil?
      # Using +item_type.constantize+ rather than +item.class+
      # allows us to retrieve destroyed objects.
      model = item_type.constantize.new
      YAML::load(object).each do |k, v|
        begin
          model.send "#{k}=", v
        rescue NoMethodError
          RAILS_DEFAULT_LOGGER.warn "Attribute #{k} does not exist on #{item_type} (Version id: #{id})."
        end
      end
      model
    end
  end
end
