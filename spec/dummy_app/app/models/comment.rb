# frozen_string_literal: true

class Comment < ApplicationRecord
  has_paper_trail versions: { class_name: "CommentVersion" }
end
