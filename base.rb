git :init
# Delete unnecessary files
  run "echo TODO > README"
  run "rm public/index.html"
  run "rm -f public/javascripts/*"
  
# Download JQuery
  run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.3.2.min.js > public/javascripts/jquery.js"
  run "curl -L http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js > public/javascripts/jquery.form.js"
  
# Download Blueprint CSS
  git :clone => "git://github.com/joshuaclayton/blueprint-css.git blueprint"
  run 'mv blueprint/blueprint/*.css public/stylesheets'
  run 'rm -rf blueprint/'
  
  
# Plugins
  plugin 'paperclip', :git => "git://github.com/thoughtbot/paperclip.git"
  plugin 'exceptional', :git => 'git://github.com/contrast/exceptional.git'
  run 'cat vendor/plugins/exceptional/exceptional.yml | sed "s/PASTE_YOUR_API_KEY_HERE/f088abbf3c2bad0180f45780fd3358f4b747dcc7/" > config/exceptional.yml'

gem "rspec", :lib => false, :version => ">=1.2.6"
gem "rspec-rails", :lib => false, :version => ">=1.2.6"
gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
gem "webrat"
gem "cucumber"
gem 'haml'
gem "right_aws"


sentinel = 'Rails::Initializer.run do |config|'
session_code = "config.action_controller.session = { :key => '_#{(1..6).map { |x| (65 + rand(26)).chr }.join}_session', :secret => '#{(1..40).map { |x| (65 + rand(26)).chr }.join}' }"
in_root do
  gsub_file 'config/environment.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
    "#{match}\n  #{session_code}"
  end
end

# Set up session store initializer
#   initializer 'session_store.rb', <<-END
# ActionController::Base.session = { :session_key => '_#{(1..6).map { |x| (65 + rand(26)).chr }.join}_session', :secret => '#{(1..40).map { |x| (65 + rand(26)).chr }.join}' }
# ActionController::Base.session_store = :active_record_store
#   END

rake('gems:install', :sudo => true)

in_root do
  run "haml --rails ."
end

rake('db:migrate')

route "map.root :controller => 'users', :action => 'new'"
 
run "rm -rf test"
generate :rspec

# get app name and insert in this file
file "config/app_config.yml", <<-END
development:
  domain: localhost:3000
  storage: s3
  bucket: wdi-dev
  path: ':attachment/:id/:style/:basename.:extension'
  access_key_id: 06F1Q32S0MFHXQJ9ER02
  secret_access_key: UylNnoWLGTxArO9sxQlitEcELKbyvDSqLz3iOqMY
  image_magick_path: '/opt/local/bin'
staging:
  domain: staging.dealblinker.com
  storage: s3
  bucket: wdi-staging
  path: ':attachment/:id/:style/:basename.:extension'
  access_key_id: 06F1Q32S0MFHXQJ9ER02
  secret_access_key: UylNnoWLGTxArO9sxQlitEcELKbyvDSqLz3iOqMY
production:
  domain: www.dealblinker.com
  storage: s3
  bucket: wdi-production
  path: ':attachment/:id/:style/:basename.:extension'
  access_key_id: 06F1Q32S0MFHXQJ9ER02
  secret_access_key: UylNnoWLGTxArO9sxQlitEcELKbyvDSqLz3iOqMY
test:
  domain: something.com
  storage: filesystem
  access_key_id: 06F1Q32S0MFHXQJ9ER02
END

file "config/initializers/_load_app_config.rb", <<-'END'
APP_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/app_config.yml")[RAILS_ENV].symbolize_keys
Paperclip.options[:command_path] = APP_CONFIG[:image_magick_path]
END

file "app/views/layouts/application.html.haml", <<-'END'
!!! Strict
%html{html_attrs}
  
  %head
    %title
      = yield(:page_title) ? yield(:page_title) + " | " : "" 
      = "WhoDesigned.it"
    %meta{"http-equiv"=>"Content-Type", :content=>"text/html; charset=utf-8"}
    = javascript_include_tag 'jquery', 'jquery.form', :cache => true
    = stylesheet_link_tag 'screen', 'application', :cache => true
    = yield(:head)
  
  %body
    .container
END
 
file ".gitignore", <<-END
.DS_Store
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
END
 
run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
run "cp config/database.yml config/example_database.yml"
 
git :add => "."
git :commit => "-m 'initial commit'"
