class Version < ActiveRecord::Base
  belongs_to :item, :polymorphic => true
  validates_presence_of :event

  def reify
    unless object.nil?
      attrs = YAML::load(object)

      # Normally a polymorphic belongs_to relationship allows us
      # to get the object we belong to by calling, in this case,
      # +item+.  However this returns nil if +item+ has been
      # destroyed, and we need to be able to retrieve destroyed
      # objects.
      #
      # Therefore we constantize the +item_type+ to get hold of
      # the class...except when the stored object's attributes
      # include a +type+ key.  If this is the case, the object
      # we belong to is using single table inheritance and the
      # +item_type+ will be the base class, not the actual subclass.
      # So we delve into the object's attributes for the +type+
      # and constantize that.

      klass = attrs['type']
      klass = item_type if klass.blank?
      model = klass.constantize.new

      attrs.each do |k, v|
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
