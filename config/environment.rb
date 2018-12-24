# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.1.6'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
  inflect.irregular 'cotizacion', 'cotizaciones'
  inflect.irregular 'orden', 'ordenes'
  inflect.irregular 'ordenid', 'ordenid'
end

# Include your application configuration below

Date::MONTHNAMES = [nil] + %w(Enero Febrero Marzo Abril Mayo Junio Julio Agosto
Septiembre Octubre Noviembre Diciembre)

ActionMailer::Base.default_charset       = "ISO-8859-1"
ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.delivery_method       = :smtp
ActionMailer::Base.perform_deliveries    = true
#ActionMailer::Base.server_settings       = {
#  :address        => "mail.apoyopublicitario.com",
#  :port           => 25,
#  :domain         => 'apoyopublicitario.com',
#  :user_name      => "notificaciones@apoyopublicitario.com",
#  :password       => "Fh*hd3BJ",
#  :authentication => :login
#}

ActionMailer::Base.server_settings       = {
  :address        => "apoyopublicitario@gmail.com",
  :port           => 587,
  :domain         => 'smtp.gmail.com',
  :authentication => :plain,
  :user_name      => "apoyopublicitario@gmail.com",
  :password       => "12077752",
  :enable_starttls_auto => true,
  :authentication => :login
}


require 'pp'
require 'ostruct'
require 'rexml-expansion-fix'
require 'extras.rb'
require 'iconv'

require 'misc_constants.rb'
require 'closed_odts.rb'
require 'statuses.rb'
require 'tabs.rb'
require 'areas.rb'
require 'panel_headers.rb'
require 'permisos.rb'
require 'filelist.rb'

#require "#{RAILS_ROOT}/vendor/gems/prawn-0.4.1/lib/prawn.rb"
#Prawn::Document::PageGeometry::SIZES["APOYO"] = [628.57, 485.14] # 22x17 0.35

VERA_VERSION = "2.1.7"

$KCODE = 'N'

ENV['RAILS_ASSET_ID'] = 'fix=1'

