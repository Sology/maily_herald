module MailyHerald

  # Provides some common patters for models that have both :name and :title attributes.
  # It adds some format constraints to :name and title attributes and makes sure
  # that they are always both set properly.
  #
  # If only :name is provided, it will be used also as a:title.
  # If only :title is provided, :name will be automatically generated out of it.
  #
  module Autonaming
    def self.included(base)
      base.extend ClassMethods
      base.send :include, MailyHerald::Autonaming::InstanceMethods

      base.class_eval do
        validates   :name,                presence: true, format: {with: /\A\w+\z/}, uniqueness: true
        validates   :title,               presence: true

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
