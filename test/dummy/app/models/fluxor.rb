class Fluxor < ActiveRecord::Base
  belongs_to :widget

  # In test/unit/model_test.rb and test/unit/serializer_test.rb, this is
  # changed on the fly, which is quite confusing.
  has_paper_trail
end
