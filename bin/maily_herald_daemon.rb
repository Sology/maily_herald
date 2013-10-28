#!/usr/bin/env ruby

require 'rubygems'
require 'daemons'
require 'maily_herald'

puts "Odpalony plik z daemonem"
Daemons.run_proc('Mmaily_heraldD.rb') do
	loop do
		puts "Odpalony plik z taskiem"
		MailyHerald.run_all
		puts "Koniec taska poczatek sleepa"
		sleep(MailyHerald::Config.time)
		puts "Koniec sleepa, od nowa"
	end
end
