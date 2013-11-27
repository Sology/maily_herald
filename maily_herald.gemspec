$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "maily_herald/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "maily_herald"
  s.version     = MailyHerald::VERSION
  s.authors     = ["Łukasz Jachymczyk"]
  s.email       = ["lukasz@sology.eu"]
  s.homepage    = "https://github.com/Sology/maily_herald"
  s.summary     = "Mailing framework for Ruby on Rails applications"
  #s.description = ""

  s.files        = `git ls-files`.split("\n")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files   = `git ls-files -- {spec,features}/**/`.split("\n")

  s.add_dependency "rails", "~> 3.2.8"
  s.add_dependency "liquid", "~> 2.6.0.rc1"
  s.add_dependency "sidekiq", "~> 2.13.0"
  s.add_dependency "timecop"
	s.add_dependency "daemons"
	s.add_dependency "sinatra"
	s.add_dependency "haml"
	s.add_dependency "coffee-rails", "~>3.2.1"
	s.add_dependency "smart_list", "~>0.9"
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers", "~>1.0"#, "~> 3.0"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "guard-spork"
  s.add_development_dependency "spork"
  s.add_development_dependency "simplecov"
  #s.add_development_dependency "timecop"
end
