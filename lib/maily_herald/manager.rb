module MailyHerald
  class Manager
    def self.handle_trigger type, entity
      mailings = Mailing.where(:trigger => type)
      mailings.each do |mailing|
        worker = Worker.new mailing
        worker.deliver_to entity
      end
    end

    def self.deliver mailing, entity
      mailing = Mailing.find_by_name(mailing) if !mailing.is_a?(Mailing)
      entity = mailing.context.scope.find(entity) if entity.is_a?(Fixnum)

      if mailing
        worker = Worker.new mailing
        worker.deliver_to entity
      end
    end

    def self.deliver_all mailing
      mailing = Mailing.find_by_name(mailing) if !mailing.is_a?(Mailing)

      if mailing
        worker = Worker.new mailing
        worker.deliver_to_all
      end
    end
  end
end
