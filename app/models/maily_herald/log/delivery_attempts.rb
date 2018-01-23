module MailyHerald
  class Log
    class DeliveryAttempts
      attr_reader :data

      def initialize data
        @data = data
      end

      def list
        @list ||= data[:delivery_attempts] || []
      end

      def list_by action
        list.select {|a| a[:action] == action}
      end

      def add action, reason, msg = nil
        list << {
          action:   action,
          reason:   reason,
          date_at:  Time.now,
          msg:      msg
        }
      end

      def count reason = nil
        reason ? list.select{|a| a[:reason] == reason}.count : list.count
      end
    end
  end
end
