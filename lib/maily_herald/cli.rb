$stdout.sync = true

require 'yaml'
require 'singleton'
require 'optparse'
require 'erb'

require 'maily_herald'

module MailyHerald
  class CLI
    include Singleton

    def parse(args=ARGV)
      setup_options(args)
      initialize_logger
    end

    def paperboy
      if options[:action] == :stop
        kill_daemon || exit(0)
      elsif options[:action] == :ping
        if daemon_running?
          puts "PONG"
          exit(0)
        else
          puts "No response..."
          exit(1)
        end
      else
        if options[:action] == :restart 
          kill_daemon 
          5.times do
            if daemon_running?
              sleep 2
            else
              break
            end

            exit(0) if daemon_running?
          end
        end
        exit(0) if options[:action] == :start && daemon_running?

        daemonize
        write_pid

        self_read, self_write = IO.pipe

        %w(INT TERM USR1 USR2).each do |sig|
          trap sig do
            self_write.puts(sig)
          end
        end

        # We don't want to load whole app and its initializers just to set up Sidekiq client
        # so let's just do that instead:
        Sidekiq.redis = {url: options[:redis_url], namespace: options[:redis_namespace]}

        redis = MailyHerald.redis
        MailyHerald.logger.info "MailyHerald running in #{RUBY_DESCRIPTION}"

        if !options[:daemon]
          MailyHerald.logger.info 'Starting processing, hit Ctrl-C to stop'
        end

        begin
          worker = Thread.new do
            while true
              unless MailyHerald::Manager.job_enqueued?
                MailyHerald.run_all 
              else
                # TODO: this is not logged
                #MailyHerald.logger.error 'Unable to queue job'
              end

              sleep 20
            end
          end

          while readable_io = IO.select([self_read])
            signal = readable_io.first[0].gets.strip
            handle_signal(signal)
          end
        rescue Interrupt
          MailyHerald.logger.info 'Shutting down'
          worker.exit
          reset_pid
          exit(0)
        end
      end
    end

    def setup_options(args)
      cli = parse_options(args)

      set_environment cli[:environment]

      MailyHerald.options = MailyHerald.read_options(cli[:config_file] || "config/maily_herald.yml").merge(cli)
    end

    def initialize_logger
      opts = {
        level: options[:verbose] ? Logger::DEBUG : Logger::INFO,
        progname: "cli",
      }
      opts[:target] = options[:logfile] if options[:logfile]

      MailyHerald::Logging.initialize(opts)
      MailyHerald.logger.info "Started with options: #{options}"
    end

    def parse_options(argv)
      opts = {}
      @parsers = {}

      @parsers[:paperboy] = OptionParser.new do |o|
        o.banner = "maily_herald paperboy [options]"

        o.on "--start", "Start Paperboy daemon" do |arg|
          opts[:action] = :start
          opts[:daemon] = true
        end

        o.on "--stop", "Stop Paperboy daemon" do |arg|
          opts[:action] = :stop
          opts[:daemon] = true
        end

        o.on "--restart", "Restart Paperboy daemon" do |arg|
          opts[:action] = :restart
          opts[:daemon] = true
        end

        o.on "--ping", "Check if Paperboy daemon is running" do |arg|
          opts[:action] = :ping
          opts[:daemon] = true
        end

        o.on '-L', '--logfile PATH', "path to writable logfile" do |arg|
          opts[:logfile] = arg
        end

        o.on '-P', '--pidfile PATH', "path to pidfile" do |arg|
          opts[:pidfile] = arg
        end
      end

      @parsers[:generic] = OptionParser.new do |o|
        o.banner = "maily_herald [paperboy] [options]"

        o.separator ""
        o.separator "Common options:"

        o.on '-c', '--config PATH', "path to YAML config file" do |arg|
          opts[:config_file] = arg
        end

        o.on '-e', '--environment ENV', "Application environment" do |arg|
          opts[:environment] = arg
        end

        o.on "-v", "--verbose", "Print more verbose output" do |arg|
          opts[:verbose] = arg
        end

        o.on_tail "-h", "--help", "Show help" do
          puts @parsers[:generic]
          puts
          puts @paperboy_parser
          exit 1
        end
      end

      if %w{paperboy}.include?(argv.first)
        opts[:mode] = argv.first.to_sym
        @parsers[argv.first.to_sym].parse!(argv)
      end
      @parsers[:generic].parse!(argv)

      opts
    end

    def parse_config(cfile)
      opts = {}
      if File.exist?(cfile)
        opts = YAML.load(ERB.new(IO.read(cfile)).result)
        opts = opts.merge(opts.delete(@environment) || {})
      end
      opts
    end

    def options
      MailyHerald.options
    end

    def daemonize
      return unless options[:daemon]

      raise ArgumentError, "You really should set a logfile if you're going to daemonize" unless options[:logfile]
      files_to_reopen = []
      ObjectSpace.each_object(File) do |file|
        files_to_reopen << file unless file.closed?
      end

      Process.daemon(true, true)

      files_to_reopen.each do |file|
        begin
          file.reopen file.path, "a+"
          file.sync = true
        rescue ::Exception
        end
      end

      [$stdout, $stderr].each do |io|
        File.open(options[:logfile], 'ab') do |f|
          io.reopen(f)
        end
        io.sync = true
      end
      $stdin.reopen('/dev/null')

      initialize_logger
    end

    def write_pid
      return unless options[:daemon]

      if path = options[:pidfile]
        File.open(path, 'w') do |f|
          f.puts Process.pid
        end
      end
    end

    def read_pid
      if path = options[:pidfile]
        File.read(path).to_i
      end
    end

    def reset_pid
      return unless options[:daemon]

      if path = options[:pidfile]
        File.open(path, 'w') do |f|
          f.puts nil
        end
      end
    end

    def daemon_running?
      read_pid > 0 && Process.kill(0, read_pid)
    rescue
      return false
    end

    def kill_daemon
      Process.kill("INT", read_pid) if read_pid > 0
      return true
    rescue
      return false
    end

    private

    def set_environment(cli_env)
      @environment = cli_env || ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
    end

    def handle_signal(sig)
      MailyHerald.logger.debug "Got #{sig} signal"
      case sig
      when 'INT'
        # Handle Ctrl-C in JRuby like MRI
        # http://jira.codehaus.org/browse/JRUBY-4637
        raise Interrupt
      when 'TERM'
        # Heroku sends TERM and then waits 10 seconds for process to exit.
        raise Interrupt
      when 'USR1'
        MailyHerald.logger.info "Received USR1, doing nothing..."
      when 'USR2'
        if MailyHerald.options[:logfile]
          MailyHerald.logger.info "Received USR2, reopening log file"
          MailyHerald::Logging.initialize_logger(target: MailyHerald.options[:logfile])
        end
      end
    end

  end
end
