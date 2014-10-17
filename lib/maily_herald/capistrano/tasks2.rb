Capistrano::Configuration.instance.load do
	namespace :maily_herald do
		desc "Stop maily_herald"
		task :stop, roles: :app do
			run "cd #{current_path}; bundle exec maily_herald --stop"
		end

		desc "Start maily_herald"
		task :start, roles: :app do
			run "cd #{current_path}; RAILS_ENV=#{rails_env} bundle exec maily_herald --start" 
		end

		desc "Restart maily_herald"
		task :restart, roles: :app do
			run "cd #{current_path}; RAILS_ENV=#{rails_env} bundle exec maily_herald --restart" 
		end
	end

	after 'deploy', 'maily_herald:restart'
end
