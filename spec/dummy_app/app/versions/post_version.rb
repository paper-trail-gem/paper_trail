# frozen_string_literal: true

class PostVersion < PaperTrail::Version
  self.table_name = "post_versions"

  # BEGIN Hack to simulate a version class that doesn't have the optional `item_subtype` column. >>>
  def item_subtype
    raise "This method should not be called!"
  end

  # We will follow Ruby's `respond_to?` method signature, including an optional boolean parameter.
  # rubocop:disable Style/OptionalBooleanParameter
  def respond_to?(method_name, include_private = false)
    # rubocop:enable Style/OptionalBooleanParameter
    return false if method_name.to_sym == :item_subtype

    super
  end
  # <<< END Hack to simulate a version class that doesn't have the optional `item_subtype` column.
end
