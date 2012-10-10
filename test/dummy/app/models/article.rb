class Article < ActiveRecord::Base
  has_paper_trail :ignore => :title,
                  :only => [:content],
                  :skip => [:file_upload],
                  :meta => {
                              :answer => 42,
                              :action => :action_data_provider_method,
                              :question => Proc.new { "31 + 11 = #{31 + 11}" },
                              :article_id => Proc.new { |article| article.id },
                              :title => :title
                            }

  def action_data_provider_method
    self.object_id.to_s
  end
end
