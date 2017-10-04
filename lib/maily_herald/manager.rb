module MailyHerald
  class Manager
    # Run scheduled sequence mailing deliveries.
    #
    # @param sequence [Sequence, String, Symbol] {Sequence} object or name
    def self.run_sequence sequence
      seqence = Sequence.find_by_name(seqence) unless seqence.is_a?(Sequence)

      sequence.run if sequence
    end

    # Run scheduled periodical mailing deliveres.
    #
    # @param mailing [PeriodicalMailing, OneTimeMailing, String, Symbol] 
    #           {AdHocMailing}, {OneTimeMailing} or {PeriodicalMailing} object or name
    def self.run_mailing mailing
      mailing = Mailing.find_by_name(mailing) unless mailing.is_a?(Mailing)

      mailing.run if mailing
    end

    # Run all scheduled mailing deliveres.
    def self.run_all
      AdHocMailing.all.each {|m| m.run}
      OneTimeMailing.all.each {|m| m.run}
      PeriodicalMailing.all.each {|m| m.run}
      Sequence.all.each {|m| m.run}
    end

    # Check if Maily sidekiq job is running.
    def self.job_enqueued?
      Sidekiq::Queue.new.detect{|j| j.klass == "MailyHerald::Async" } || 
        Sidekiq::Workers.new.detect{|w, msg| msg["payload"]["class"] == "MailyHerald::Async" } ||
        Sidekiq::RetrySet.new.detect{|j| j.klass = "MailyHerald::Async" }
    end
  end
end
