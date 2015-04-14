module MailyHerald
  class Manager
    # Delivers single {OneTimeMailing} to entity.
    #
    # @param mailing [OneTimeMailing, String, Symbol] {Mailing} object or name
    # @param entity [ActiveRecord::Base] Entity object that belongs to +mailing+ {Context} scope
    def self.deliver mailing, entity
      mailing = Mailing.find_by_name(mailing) unless mailing.is_a?(Mailing)
      entity = mailing.context.scope.find(entity) if entity.is_a?(Fixnum)

      mailing.deliver_to entity if mailing
    end

    # Run scheduled sequence mailing deliveries.
    #
    # @param sequence [Sequence, String, Symbol] {Sequence} object or name
    def self.run_sequence sequence
      seqence = Sequence.find_by_name(seqence) unless seqence.is_a?(Sequence)

      sequence.run if sequence
    end

    # Run scheduled periodical mailing deliveres.
    #
    # @param mailing [PeriodicalMailing, String, Symbol] {PeriodicalMailing} object or name
    def self.run_mailing mailing
      mailing = Mailing.find_by_name(mailing) unless mailing.is_a?(Mailing)

      mailing.run if mailing
    end

    # Run all scheduled mailing deliveres.
    def self.run_all
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
