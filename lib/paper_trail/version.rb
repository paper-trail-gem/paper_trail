class Version < ActiveRecord::Base
  belongs_to :item, :polymorphic => true
  has_many :version_associations, :dependent => :destroy
  
  validates_presence_of :event

  def self.with_item_keys(item_type, item_id)
    scoped(:conditions => { :item_type => item_type, :item_id => item_id })
  end

  scope :subsequent, lambda { |version|
    where(["#{self.primary_key} > ?", version.is_a?(self) ? version.id : version]).order("#{self.primary_key} ASC")
  }

  scope :preceding, lambda { |version|
    where(["#{self.primary_key} < ?", version.is_a?(self) ? version.id : version]).order("#{self.primary_key} DESC")
  }

  scope :after, lambda { |timestamp|
    # TODO: is this :order necessary, considering its presence on the has_many :versions association?
    where(['created_at > ?', timestamp]).order("created_at ASC, #{self.primary_key} ASC")
  }

  scope :transact, lambda { |id|
    where(['transaction_id = ?',id])
  }
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
    without_identity_map do
      options.reverse_merge!(:version_at => created_at,
      :has_one => false,
      :has_many => false)

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
          inheritance_column_name = item_type.constantize.inheritance_column
          class_name = attrs[inheritance_column_name].blank? ? item_type : attrs[inheritance_column_name]
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

        model.send "#{model.class.version_name}=", self

        unless options[:has_one] == false
          reify_has_ones(model,options)
        end

        unless options[:has_many] == false
          reify_has_manys(model,options)
        end

        model
      end
    end
  end

  # Returns what changed in this version of the item.  Cf. `ActiveModel::Dirty#changes`.
  # Returns nil if your `versions` table does not have an `object_changes` text column.
  def changeset
    if self.class.column_names.include? 'object_changes'
      if changes = object_changes
        HashWithIndifferentAccess[YAML::load(changes)]
      else
        {}
      end
    end
  end

  def transact
    Version.transact(transaction_id)
  end

  def rollback
    #rollback all changes within transaction
    transaction do
      transact.reverse_each do |version|
        version.reify.save!
      end
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
    self.class.with_item_keys(item_type, item_id)
  end

  def next
    sibling_versions.subsequent(self).first
  end

  def previous
    sibling_versions.preceding(self).first
  end

  def index
    sibling_versions.select(:id).order("id ASC").map(&:id).index(self.id)
  end

  private
  # In Rails 3.1+, calling reify on a previous version confuses the
  # IdentityMap, if enabled. This prevents insertion into the map.
  def without_identity_map(&block)
    if defined?(ActiveRecord::IdentityMap) && ActiveRecord::IdentityMap.respond_to?(:without)
      ActiveRecord::IdentityMap.without(&block)
    else
      block.call
    end
  end

  # Restore the `model`'s has_one associations as they were when this version was
  # superseded by the next (because that's what the user was looking at when they
  # made the change).
  #
  # The `lookback` sets how many seconds before the model's change we go.
  def reify_has_ones(model, options)
    model.class.reflect_on_all_associations(:has_one).each do |assoc|
      version=Version.joins(:version_associations).
        where(["item_type = ?",assoc.class_name]).
        where(["foreign_key_name = ?",assoc.primary_key_name]).
        where(["foreign_key_id = ?", model.id]).
        where(["created_at >= ? OR transaction_id = ?", options[:version_at], transaction_id]).
        order("#{self.class.table_name}.id ASC").
        limit(1).first
      if(version)
        if(version.event=='create')
          if(child=version.item)
            child.mark_for_destruction
            model.send(assoc.name.to_s+"=",nil)
          end
        else
          logger.info "Reify #{child}"
          child=version.reify(options)
          model.appear_as_new_record do
            model.send(assoc.name.to_s+"=",child)
          end
        end
      end
    end
  end

  # Restore the `model`'s has_many associations as they were at version_at timestamp
  # We lookup the first child versions after version_at timestamp or in same transaction.
  def reify_has_manys(model,options = {})
    model.class.reflect_on_all_associations(:has_many).each do |assoc|
      next if(assoc.name==:versions)
      version_id_subquery=VersionAssociation.joins(:version).
        select("MIN(version_id)").
        where(["item_type = ?",assoc.class_name]).
        where(["foreign_key_name = ?",assoc.primary_key_name]).
        where(["foreign_key_id = ?", model.id]).
        where(["created_at >= ? OR transaction_id = ?", options[:version_at], transaction_id]).
        group("item_id").to_sql
      versions=Version.where("id IN (#{version_id_subquery})")
      
      versions.each do |version|
        if(version.event=='create')
          if(child=version.item)
            child.mark_for_destruction
            model.send(assoc.name).delete child
          end
        else
          child = version.reify(options)
          model.appear_as_new_record do
            model.send(assoc.name) << child
          end
        end
      end
    end
  end
end
