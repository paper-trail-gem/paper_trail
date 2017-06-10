class Gadget < ActiveRecord::Base
  has_paper_trail ignore: :brand
end
