module MailyHerald
  class Log
    class Opens
      attr_reader :data

      def initialize data
        @data = data
      end

      def list
        @list ||= data[:opens] || []
      end

      def add ip_address, user_agent
        list << {
          ip_address: ip_address,
          user_agent: user_agent,
          opened_at:  Time.zone.now
        }
      end

      def count
        list.count
      end
    end
  end
end
