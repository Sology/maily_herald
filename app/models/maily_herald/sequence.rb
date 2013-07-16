module MailyHerald
  class Sequence < ActiveRecord::Base
    has_many    :records,       :as => :mailing, :class_name => "MailingRecord"

    validates   :context_name,  :presence => true
    validates   :name,          :presence => true
    validates   :mode,          :presence => true, :inclusion => {:in => [:chronological, :periodical]}

    def mode
      read_attribute(:mode).to_sym
    end
    def mode=(value)
      write_attribute(:mode, value.to_s)
    end
  end
end
