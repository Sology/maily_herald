require 'rubygems'
require 'sinatra'
require 'haml'

module MailyHerald
	module Webui
		class App < Sinatra::Application
			get '/' do
				haml :index
			end
		end
	end
end
