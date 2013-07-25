module MailyHerald
  class MailingRecord < MailyHerald::Record
    belongs_to  :mailing

    validates   :mailing,       :presence => true

    scope       :for_mailing,   lambda {|mailing| where(:mailing_id => mailing.id, :mailing_type => mailing.class.base_class) }
  end
end
