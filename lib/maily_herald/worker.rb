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
      Mailer.generic(@mailing.destination_for(entity), prepare_for(entity)).deliver
    end
  end
end
