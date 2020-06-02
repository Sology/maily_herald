module MailyHerald
  class Log
    class Clicks
      attr_reader :data

      # Wrapper for each MailyHerald::Log 'data[:clicks]'
      # Initialized with just 'data' attribute for given MailyHerald::Log
      def initialize data
        @data = data
      end

      # Returns list of all tracked clicks.
      #
      # @return [Array<Hash{String => Symbol, Date, String}>] list The list of hashes
      # @option list[Hash][String] [String]     :ip_address Ip address from which link was clicked
      # @option list[Hash][String] [String]     :user_agent Software agent that is acting on behalf of a user - most likely web browser name
      # @option list[Hash][String] [String]     :dest_url The destination URL that the click would land on
      # @option list[Hash][String] [clicked_at] :date_at Date when link was clicked
      def list
        @list ||= data[:clicks] || []
      end

      # Adds new click to list
      #
      # @param ip_address [String] Ip address from which link was clicked
      # @param user_agent [String] Software agent that is acting on behalf of a user - most likely web browser name
      # @param dest_url   [String] The destination URL that the click would land on
      # @return [Array<Hash{String => Symbol, Date, String}>] list List of all delivery attempts
      def add ip_address, user_agent, dest_url
        list << {
          ip_address: ip_address,
          user_agent: user_agent,
          dest_url:   dest_url,
          clicked_at: Time.zone.now
        }
      end

      # Return count of clicks
      #
      # @return [Integer] clicks count
      def count
        list.count
      end
    end
  end
end
