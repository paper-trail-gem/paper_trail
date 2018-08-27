# frozen_string_literal: true

# Note that there is no `type` column for this subclassed model, so changes to
# Management objects should result in Versions which have an item_type of
# Customer.
class Management < Customer
end
