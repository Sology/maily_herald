module MailyHerald
  class Engine < ::Rails::Engine
    isolate_namespace MailyHerald

    config.generators do |g|
      g.test_framework      :rspec,         fixture: false
      g.fixture_replacement :factory_girl,  dir: 'spec/factories'
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
  end
end
