$stdout.sync = true

require 'yaml'
require 'singleton'
require 'optparse'
require 'erb'

require 'maily_herald'
require 'clockwork'

module MailyHerald
  class CLI
    include Singleton
    include Clockwork

    def parse
    end

    def run
      handler do |job|
        MailyHerald.run_all
      end

      every(2.minutes, "job")

      Clockwork::run
    end

  end
end
