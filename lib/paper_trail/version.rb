class Version < ActiveRecord::Base
  belongs_to :item, :polymorphic => true
  has_many :version_associations, :dependent => :destroy
  
  validates_presence_of :event

  scope :with_item_keys, lambda { |item_type, item_id|
    where(:item_type => item_type, :item_id => item_id)
  }

  scope :subsequent, lambda { |version|
    where(["id > ?", version.is_a?(Version) ? version.id : version]).order("id ASC")
  }

  scope :preceding, lambda { |version|
    where(["id < ?", version.is_a?(Version) ? version.id : version]).order("id DESC")
  }

  scope :after, lambda { |timestamp|
    # TODO: is this :order necessary, considering its presence on the has_many :versions association?
    where(['created_at > ?', timestamp]).order('created_at ASC, id ASC')
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
    options.reverse_merge!(:version_at => created_at)
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
				sti=item_type.constantize.inheritance_column
        class_name = attrs[sti].blank? ? item_type : attrs[sti]
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
        reify_has_ones(model,options)
      end

      unless options[:has_many] == false
        reify_has_manys(model,options)
      end

      model
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
    Version.with_item_keys(item_type, item_id)
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
  # Restore the `model`'s has_one associations as they were at version_at timestamp
  # We lookup the first child version after version_at timestamp or in same transaction.
  def reify_has_ones(model,options = {})
    model.class.reflect_on_all_associations(:has_one).each do |assoc|
      version_association=VersionAssociation.includes(:version).
        where(["item_type = ?",assoc.class_name]).
        where(["foreign_key_name = ?",assoc.primary_key_name]).
        where(["foreign_key_id = ?", model.id]).
        where(['created_at >= ? OR transaction_id = ?', options[:version_at], transaction_id]).
        order('versions.id ASC').
        limit(1).first
      if(version_association)
        if(version.event=='create')
          child=version_association.item
          child.mark_for_destruction
        else
          child=version_association.version.reify(options)
        end
        model.send(assoc.name.to_s+"=",child)
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
          child=version.item
          child.mark_for_destruction
        else
          child=version.reify(options)
        end
        model.send(assoc.name) << child
      end
    end
  end
end
