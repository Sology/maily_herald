if Gem::Specification.find_by_name('capistrano').version >= Gem::Version.new('3.0.0')
  load File.expand_path('../capistrano/tasks.cap', __FILE__)
else
  require_relative 'capistrano/tasks2'
end
