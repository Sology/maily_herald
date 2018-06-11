module MailyHerald
  class Engine < ::Rails::Engine
    isolate_namespace MailyHerald

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, :dir => 'spec/support/factories'
    end

    config.to_prepare do
      require_dependency 'maily_herald/model_extensions'

      MailyHerald.contexts.each do|n, c|
        if c.model
          unless c.model.included_modules.include?(MailyHerald::ModelExtensions)
            c.model.send(:include, MailyHerald::ModelExtensions)
          end
        end
      end
    end

    initializer :append_migrations do |app|
      # This prevents migrations from being loaded twice from the inside of the
      # gem itself (dummy test app)
      if app.root.to_s !~ /#{root}/
        config.paths['db/migrate'].expanded.each do |migration_path|
          app.config.paths['db/migrate'] << migration_path
        end
      end
    end
  end
end
