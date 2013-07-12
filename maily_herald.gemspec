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
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.add_dependency "rails", "~> 3.2.8"
  s.add_dependency "liquid", "~> 2.6.0"
  s.add_dependency "sidekiq", "~> 2.13.0"
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers", "~>1.0"#, "~> 3.0"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "database_cleaner"
end
