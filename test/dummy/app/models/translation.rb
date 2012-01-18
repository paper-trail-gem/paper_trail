class Translation < ActiveRecord::Base
  has_paper_trail :if     => Proc.new { |t| t.language_code == 'US' },
                  :unless => Proc.new { |t| t.type == 'DRAFT'       }
end
