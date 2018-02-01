module MailyHerald
  class Log
    class DeliveryAttempts
      attr_reader :data

      # Wrapper for each MailyHerald::Log 'data[:delivery_attempts]'
      # Initialized with just 'data' attribute for given MailyHerald::Log
      def initialize data
        @data = data
      end

      # Returns list of all delivery attempts
      #
      # @return [Array<Hash{String => Symbol, Date, String}>] list The list of hashes
      # @option list[Hash][String] [Symbol]   :action Initial action that caused error, e.g. :retry (as in retry sending email)
      # @option list[Hash][String] [Symbol]   :reason Reason why it failed - in most cases it will be just :error
      # @option list[Hash][String] [DateTime] :date_at Date and time when error occured
      # @option list[Hash][String] [String]   :msg More etailed information about an error
      def list
        @list ||= data[:delivery_attempts] || []
      end

      # Returns list of delivery attempts filtered by :action
      #
      # @param action [Symbol] Specific action you want to filter by e.g. :retry
      # @return [Array<Hash{String => Symbol, Date, String}>] list The list of hashes
      # @option list[Hash][String] [Symbol]   :action Initial action that caused error, e.g. :retry (as in retry sending email)
      # @option list[Hash][String] [Symbol]   :reason Reason why it failed - in most cases it will be just :error
      # @option list[Hash][String] [DateTime] :date_at Date and time when error occured
      # @option list[Hash][String] [String]   :msg More etailed information about an error
      def list_by action
        list.select {|a| a[:action] == action}
      end

      # Adds new delivery attempt to list
      #
      # @param action [Symbol] Specific action that caused error e.g. :retry
      # @param reason [Symbol] Reason why it failed e.g. :error
      # @param msg    [String] More detailed information about error
      # @return [Array<Hash{String => Symbol, Date, String}>] list List of all delivery attempts
      def add action, reason, msg = nil
        list << {
          action:   action,
          reason:   reason,
          date_at:  Time.now,
          msg:      msg
        }
      end

      # Return count of delivery attempts filtered by reason
      #
      # @param reason [Symbol] Reason you want to filter by e.g. :error
      # @return [Integer] Filtered delivery attempts count
      def count reason = nil
        reason ? list.select{|a| a[:reason] == reason}.count : list.count
      end
    end
  end
end
