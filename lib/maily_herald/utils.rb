module MailyHerald
  module Utils
    def self.random_hex(n)
      SecureRandom.hex(n)
    end
  end
end
