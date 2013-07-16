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

        unless record = @mailing.record_for(entity)
          record = @mailing.records.build
          record.entity = entity
        end
        record.last_delivery = DateTime.now
        record.status = "ok"
        record.save
      else
        # TODO
      end
    end
  end
end
