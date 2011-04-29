# TODO: do we need that here ?
require 'active_record'

require File.join(File.expand_path(__FILE__), '..', 'spam_classifier', 'spam_classifier')

require File.join(File.expand_path(__FILE__), '..', 'spam_classifier', 'base')
require File.join(File.expand_path(__FILE__), '..', 'spam_classifier', 'spam_classification_index')
require File.join(File.expand_path(__FILE__), '..', 'spam_classifier', 'words')
require File.join(File.expand_path(__FILE__), '..', 'spam_classifier', 'features')
require File.join(File.expand_path(__FILE__), '..', 'spam_classifier', 'training_examples')

# path = Gem.searcher.find('spam_classifier').full_gem_path
# Dir["#{path}/lib/tasks/*.rake"].each { |ext| load ext }

ActiveRecord::Base.establish_connection(:adapter => 'mysql', :username => 'root', :password => 'root', :database => 'soundcloud_development')
