git :init
# Delete unnecessary files
  run "echo TODO > README"
  run "rm public/index.html"
  run "rm public/favicon.ico"
  run "rm public/robots.txt"
  run "rm -f public/javascripts/*"
  
# Download JQuery
  run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.3.1.min.js > public/javascripts/jquery.js"
  run "curl -L http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js > public/javascripts/jquery.form.js"
  
# Download Blueprint CSS
  git :clone => "git://github.com/joshuaclayton/blueprint-css.git public/stylesheets/blueprint"
 
plugin 'open_id_authentication', :git => 'git://github.com/rails/open_id_authentication.git', :submodule => true
plugin 'role_requirement', :git => 'git://github.com/timcharper/role_requirement.git', :submodule => true
plugin 'restful-authentication', :git => 'git://github.com/technoweenie/restful-authentication.git', :submodule => true
gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
gem 'ruby-openid', :lib => 'openid'
gem 'sqlite3-ruby', :lib => 'sqlite3'
gem 'haml'
gem 'mislav-will_paginate', :lib => 'will_paginate', :source => 'http://gems.github.com'

sentinel = 'Rails::Initializer.run do |config|'
session_code = "config.action_controller.session = { :key => '_#{(1..6).map { |x| (65 + rand(26)).chr }.join}_session', :secret => '#{(1..40).map { |x| (65 + rand(26)).chr }.join}' }"
in_root do
  gsub_file 'config/environment.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
    "#{match}\n  #{session_code}"
  end
end

# Set up session store initializer
  initializer 'session_store.rb', <<-END
ActionController::Base.session = { :session_key => '_#{(1..6).map { |x| (65 + rand(26)).chr }.join}_session', :secret => '#{(1..40).map { |x| (65 + rand(26)).chr }.join}' }
ActionController::Base.session_store = :active_record_store
  END

rake('gems:install', :sudo => true)

in_root do
  run "haml -—rails ."
end
run "mkdir public/stylesheets/sass"
run "touch public/stylesheets/sass/application.sass"
  rake('db:sessions:create')
  generate("authenticated", "user session")
  generate("roles", "Role User")
  rake('open_id_authentication:db:create')
  rake('db:migrate')


 
if yes?("Do you want to use RSpec?")
  run "rm -rf test"
  generate :rspec
end
 
file ".gitignore", <<-END
.DS_Store
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
END
 
run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
run "cp config/database.yml config/example_database.yml"


 
git :add => ".", :commit => "-m 'initial commit'"
