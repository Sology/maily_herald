module MailyHerald
  class Worker
    def initialize mailing
      @mailing = mailing
      @context = @mailing.context
    end

    def prepare_for item
      drop = @context.drop_for item 
      template = Liquid::Template.parse(@mailing.template)
      template.render drop
    end

    def deliver_to entity
      if @mailing.mailer_name == 'generic'
        Mailer.generic(@mailing.destination_for(entity), prepare_for(entity)).deliver

        record = @mailing.find_or_initialize_record_for(entity)
        record.last_delivery = DateTime.now
        record.status = "ok"
        record.save
      else
        # TODO
      end
    end

    def deliver_to_all
      @context.scope.each do |entity|
        deliver_to entity
      end
    end
  end
end
