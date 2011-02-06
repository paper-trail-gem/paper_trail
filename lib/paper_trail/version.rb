class Version < ActiveRecord::Base
  belongs_to :item, :polymorphic => true
  validates_presence_of :event

  named_scope :with_item_keys, lambda { |item_type, item_id| {
    :conditions => { :item_type => item_type, :item_id => item_id }
  } }

  named_scope :subsequent, lambda { |version| {
    :conditions => ["id > ?", version.is_a?(ActiveRecord::Base) ? version.id : version],
    :order      => "id ASC",
  } }

  named_scope :preceding, lambda { |version| {
    :conditions => ["id < ?", version.is_a?(ActiveRecord::Base) ? version.id : version],
    :order      => "id DESC",
  } }

  named_scope :after, lambda { |timestamp| {
    :conditions => ['created_at > ?', timestamp],
    # TODO: is this :order necessary, considering its presence on the has_many :versions association?
    :order      => 'created_at ASC, id ASC'
  } }

  # Restore the item from this version.
  #
  # This will automatically restore all :has_one associations as they were "at the time",
  # if they are also being versioned by PaperTrail.  NOTE: this isn't always guaranteed
  # to work so you can either change the lookback period (from the default 3 seconds) or
  # opt out.
  #
  # Options:
  # +:has_one+   set to `false` to opt out of has_one reification.
  #              set to a float to change the lookback time (check whether your db supports
  #              sub-second datetimes if you want them).
  def reify(options = {})
    options.reverse_merge! :has_one => 3

    unless object.nil?
      attrs = YAML::load object

      # Normally a polymorphic belongs_to relationship allows us
      # to get the object we belong to by calling, in this case,
      # +item+.  However this returns nil if +item+ has been
      # destroyed, and we need to be able to retrieve destroyed
      # objects.
      #
      # In this situation we constantize the +item_type+ to get hold of
      # the class...except when the stored object's attributes
      # include a +type+ key.  If this is the case, the object
      # we belong to is using single table inheritance and the
      # +item_type+ will be the base class, not the actual subclass.
      # If +type+ is present but empty, the class is the base class.

      if item
        model = item
      else
        class_name = attrs['type'].blank? ? item_type : attrs['type']
        klass = class_name.constantize
        model = klass.new
      end

      attrs.each do |k, v|
        begin
          model.send :write_attribute, k.to_sym , v
        rescue NoMethodError
          logger.warn "Attribute #{k} does not exist on #{item_type} (Version id: #{id})."
        end
      end

      model.version = self

      unless options[:has_one] == false
        reify_has_ones model, options[:has_one]
      end

      model
    end
  end

  # Returns who put the item into the state stored in this version.
  def originator
    previous.try :whodunnit
  end

  # Returns who changed the item from the state it had in this version.
  # This is an alias for `whodunnit`.
  def terminator
    whodunnit
  end

  def sibling_versions
    Version.with_item_keys(item_type, item_id)
  end

  def next
    sibling_versions.subsequent(self).first
  end

  def previous
    sibling_versions.preceding(self).first
  end

  def index
    sibling_versions.all(:select => :id, :order => "id ASC").map(&:id).index(self.id)
  end

  private

  # Restore the `model`'s has_one associations as they were when this version was
  # superseded by the next (because that's what the user was looking at when they
  # made the change).
  #
  # The `lookback` sets how many seconds before the model's change we go.
  def reify_has_ones(model, lookback)
    model.class.reflect_on_all_associations(:has_one).each do |assoc|
      child = model.send assoc.name
      if child.respond_to? :version_at
        # N.B. we use version of the child as it was `lookback` seconds before the parent was updated.
        # Ideally we want the version of the child as it was just before the parent was updated...
        # but until PaperTrail knows which updates are "together" (e.g. parent and child being
        # updated on the same form), it's impossible to tell when the overall update started;
        # and therefore impossible to know when "just before" was.
        if (child_as_it_was = child.version_at(created_at - lookback.seconds))
          child_as_it_was.attributes.each do |k,v|
            model.send(assoc.name).send :write_attribute, k.to_sym, v rescue nil
          end
        else
          model.send "#{assoc.name}=", nil
        end
      end
    end
  end

end
