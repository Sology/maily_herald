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
        MailyHerald::Async.perform_async
      end

      every(1.minutes, "job")

      Clockwork::run
    end

  end
end
