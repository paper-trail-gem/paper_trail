# frozen_string_literal: true

# Demonstrates the `only` and `ignore` attributes, among other things.
class Article < ActiveRecord::Base
  has_paper_trail(
    ignore: [
      :title, {
        abstract: proc { |obj|
          ["ignore abstract", "Other abstract"].include? obj.abstract
        }
      }
    ],
    only: [:content, { abstract: proc { |obj| obj.abstract.present? } }],
    skip: [:file_upload],
    meta: {
      answer: 42,
      action: :action_data_provider_method,
      question: proc { "31 + 11 = #{31 + 11}" },
      article_id: proc { |article| article.id },
      title: :title
    }
  )

  def action_data_provider_method
    object_id.to_s
  end
end
