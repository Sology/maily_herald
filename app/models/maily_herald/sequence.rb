module MailyHerald
  class Sequence < ActiveRecord::Base
    has_many    :records,             :class_name => "MailyHerald::SequenceRecord"
    has_many    :mailings,            :class_name => "MailyHerald::Mailing"

    validates   :context_name,        :presence => true
    validates   :name,                :presence => true
    validates   :mode,                :presence => true, :inclusion => {:in => [:chronological, :periodical]}

    def mode
      read_attribute(:mode).to_sym
    end
    def mode=(value)
      write_attribute(:mode, value.to_s)
    end

    def context
      @context ||= MailyHerald.context context_name
    end

    def record_for entity
      self.records.for_entity(entity).first
    end

    def find_or_initialize_record_for entity
      sequence_record = record_for entity
      unless sequence_record
        sequence_record = self.records.build
        sequence_record.entity = entity
      end
      sequence_record
    end

    def pending_mailings_for entity
      if record = record_for(entity)
        self.mailings.where("id not in (?)", record.delivered_mailings_ids).order("delay_time asc")
      else
        self.mailings.order("delay_time asc")
      end
    end

    def delivered_mailings_for entity
      if record = record_for(entity)
        self.mailings.where("id in (?)", record.delivered_mailings_ids).order("delay_time asc")
      else
        self.mailings.where(:id => nil)
      end
    end

    def evaluate_start_var_for entity
      template = Liquid::Template.parse(self.start_var)
      drop = self.context.drop_for entity 

      liquid_context = Liquid::Context.new([drop, template.assigns], template.instance_assigns, template.registers, true, {})
      drop.context = liquid_context
      liquid_context[self.start_var]
    end

    def mailing name
      if Mailing.table_exists?
        mailing = Mailing.find_or_initialize_by_name(name)
        mailing.sequence = self
        if block_given?
          yield(mailing)
        end
        mailing.save
        mailing
      end
    end

    def run
      self.context.scope.each do |entity|
        case self.mode
        when :periodical
        when :chronological
          start_time = evaluate_start_var_for entity

          if Time.now >= start_time
            sequence_record = find_or_initialize_record_for(entity)

            mailing = pending_mailings_for(entity).first
            if mailing && Time.now >= start_time + mailing.delay_time
              # TODO make it atomic
              mailing.deliver_to entity
              sequence_record.add_delivered_mailing mailing
              sequence_record.delivered_at = Time.now
              sequence_record.save
            end
          end
        end
      end
    end
  end
end
