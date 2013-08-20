require 'rubygems'
require 'spork'

#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  # Configure Rails Envinronment
  ENV["RAILS_ENV"] = "test"

  require 'simplecov'
  SimpleCov.start do
    add_filter '/config/'
    add_filter '/spec/dummy'
    add_group 'Controllers', 'app/controllers'
    add_group 'Helpers', 'app/helpers'
    add_group 'Mailers', 'app/mailers'
    add_group 'Models', 'app/models'
    add_group 'Libraries', 'lib'
    add_group 'Specs', 'spec'
  end

  require File.expand_path("../dummy/config/environment.rb",  __FILE__)

  require 'rspec/rails'
  require 'rspec/autorun'
  require "factory_girl_rails"
  require "database_cleaner"
  require 'shoulda/matchers/integrations/rspec'
  require 'sidekiq/testing'
  require 'timecop'

  ENGINE_RAILS_ROOT=File.join(File.dirname(__FILE__), '../')


  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[File.join(ENGINE_RAILS_ROOT, "spec/support/**/*.rb")].each {|f| require f }

  keep_tables = %w[maily_herald_mailings maily_herald_sequences maily_herald_subscription_groups]
  RSpec.configure do |config|
    config.use_transactional_fixtures = false
    config.before(:suite) do
      DatabaseCleaner.strategy = :truncation, {:except => keep_tables}
      DatabaseCleaner.clean_with(:truncation, {:except => keep_tables})
    end
    config.before(:each) do
      DatabaseCleaner.start
    end
    config.after(:each) do
      DatabaseCleaner.clean
    end
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.

end

