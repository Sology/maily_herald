module MailyHerald
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    def check_changed_attribute obj, attr_name
      if Rails::VERSION::MAJOR == 5
        obj.saved_change_to_attribute?(attr_name.to_sym)
      else
        obj.send "#{attr_name}_changed?"
      end
    end
  end
end
