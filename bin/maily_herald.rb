require 'rubygems'
require_relative '../lib/maily_herald/config'

loop do
	MailyHerald.run_all
	sleep(MailyHerald::Config.time)
end
