module MailyHerald
  class SequenceRecord < MailyHerald::Record
    belongs_to  :sequence

    validates   :sequence,      :presence => true

    scope       :for_sequence,   lambda {|sequence| where(:mailing_id => sequence.id, :mailing_type => sequence.class.base_class) }

    def delivered_mailings_ids
      self.data[:delivered_mailings] || []
    end

    def add_delivered_mailing mailing
      self.data[:delivered_mailings] ||= []
      self.data[:delivered_mailings].push mailing.respond_to?(:id) ? mailing.id : mailing.to_i
    end
  end
end
