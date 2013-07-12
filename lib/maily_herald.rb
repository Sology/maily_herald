require "maily_herald/engine"

module MailyHerald
  autoload :Utils,          	'maily_herald/utils'
  autoload :Context,          'maily_herald/context'
  autoload :Worker,          	'maily_herald/worker'

  def self.setup
    yield self
  end

	def self.context name, &block
		name = name.to_s

		if block_given?
			@@contexts ||= {}
			@@contexts[name] ||= MailyHerald::Context.new
			yield @@contexts[name]
		else
			@@contexts[name]
		end
	end

	def self.contexts
		@@contexts
	end
end

require 'liquid'
