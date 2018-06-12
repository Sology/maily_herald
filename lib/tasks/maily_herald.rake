namespace :maily_herald do
  namespace :upgrade do
    desc "Transition from in-app to engine-based DB migrations"
    task :migrations_fixup => :environment do
      migrations = MailyHerald::Engine.root.join("db/migrate").entries.each_with_object({}) do |entry, hash|
        entry.basename.to_s.match(/\A(\d+)_(\w+)\.rb\z/) do |md|
          hash[md[2]] = md[1]
        end
      end

      sqls = []
      cmds = []
      ::Rails.root.join("db/migrate").entries.each do |entry|
        entry.basename.to_s.match(/\A(\d+)_(\w+)\.maily_herald\.rb\z/) do |md|
          name = md[2]
          local_id = md[1]

          id = migrations[name]

          sqls << "UPDATE schema_migrations SET version = '#{id}' WHERE version = '#{local_id}';"
          cmds << "rm #{(::Rails.root.join("db/migrate") + entry)}"
        end
      end

      puts "Fix your migration files by executing following shell commands:"
      cmds.each{|cmd| puts "\t#{cmd}"}
      puts "\nFix your database schema by executing following SQL commands:"
      sqls.each{|cmd| puts "\t#{cmd}"}
    end
  end
end
