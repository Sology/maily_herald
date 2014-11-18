module MailyHerald
  module Autonaming
    def self.included(base)
      base.extend ClassMethods
      base.send :include, MailyHerald::Autonaming::InstanceMethods

      base.class_eval do
        before_validation do
          if self.title && !self.name
            self.name = self.title.parameterize.underscore
          elsif self.name && !self.title
            self.title = self.name
          end
        end
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def self.included(base)
        base.extend ClassMethods
      end

      def to_s
        self.title || self.name
      end
    end
  end
end
