# == Schema Information
#
# Table name: widgets
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  an_integer  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Widget < ActiveRecord::Base
  has_paper_trail
end
