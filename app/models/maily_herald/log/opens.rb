module MailyHerald
  class Log
    class Opens
      attr_reader :data

      # Wrapper for each MailyHerald::Log 'data[:opens]'
      # Initialized with just 'data' attribute for given MailyHerald::Log
      def initialize data
        @data = data
      end

      # Returns list of all tracked opens.
      #
      # @return [Array<Hash{String => Symbol, Date, String}>] list The list of hashes
      # @option list[Hash][String] [String]     :ip_address Ip address from which email was opened
      # @option list[Hash][String] [String]     :user_agent Software agent that is acting on behalf of a user - most likely web browser name
      # @option list[Hash][String] [opened_at]  :date_at Date when email was opened
      def list
        @list ||= data[:opens] || []
      end

      # Adds new open to list
      #
      # @param ip_address [String] Ip address from which email was opened
      # @param user_agent [String] Software agent that is acting on behalf of a user - most likely web browser name
      # @return [Array<Hash{String => Symbol, Date, String}>] list List of all delivery attempts
      def add ip_address, user_agent
        list << {
          ip_address: ip_address,
          user_agent: user_agent,
          opened_at:  Time.zone.now
        }
      end

      # Return count of opens
      #
      # @return [Integer] Opens count
      def count
        list.count
      end
    end
  end
end
