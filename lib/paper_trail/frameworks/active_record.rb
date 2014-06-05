# This file only needs to be loaded if the gem is being used outside of Rails, since otherwise
# the model(s) will get loaded in via the `Rails::Engine`
Dir[File.join(File.dirname(__FILE__), 'active_record', 'models', 'paper_trail', '*.rb')].each do |file|
  require "paper_trail/frameworks/active_record/models/paper_trail/#{File.basename(file, '.rb')}"
end
