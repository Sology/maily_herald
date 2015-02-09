# encoding: UTF-8

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
  s.license     = "LGPL-3.0"
  s.description = s.summary = "Email processing solution for Ruby on Rails applications"

  s.files       = `git ls-files`.split("\n")
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files  = `git ls-files -- {spec,features}/**/`.split("\n")

  s.add_dependency "rails", "> 3.2"
  s.add_dependency "liquid", "~> 2.6.1"
  s.add_dependency "sidekiq", "~> 2.17.8"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "timecop"
  s.add_development_dependency "spring-commands-rspec"
  s.add_development_dependency "yard"
  s.add_development_dependency "redcarpet" # for yard markdown formatting
end
