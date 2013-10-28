Capistrano::Configuration.instance.load do

	_cset(:maily_herald_default_hooks) { true }

	if fetch(:maily_herald_default_hooks)
		after "deploy", "maily_herald:restart"
	end

	namespace :maily_herald do
		desc "Stop maily_herald"
		task :stop, :roles => :app do
			run "cd #{current_path}; bundle exec lib/maily_herald_daemon.rb stop"
		end

		desc "Start maily_herald"
		task :start, :roles => :app do
			run "cd #{current_path}; RAILS_ENV=#{rails_env} bundle exec lib/maily_herald_daemon.rb start" 
		end

		desc "Restart maily_herald"
		task :restart, :roles => :app do
			stop
			start
		end
	end
end
