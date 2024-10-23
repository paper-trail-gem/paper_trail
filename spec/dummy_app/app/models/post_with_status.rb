# frozen_string_literal: true

# This model tests ActiveRecord::Enum, which was added in AR 4.1
# http://edgeguides.rubyonrails.org/4_1_release_notes.html#active-record-enums
class PostWithStatus < ApplicationRecord
  has_paper_trail

  if ActiveRecord::VERSION::MAJOR >= 7
    enum :status, { draft: 0, published: 1, archived: 2 }
  else
    enum status: { draft: 0, published: 1, archived: 2 }
  end
end
