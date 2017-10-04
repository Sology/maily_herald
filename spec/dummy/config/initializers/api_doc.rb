unless Rails.env.production?
  Rails.application.config.middleware.use Rack::Static, urls: ['/doc/api/v1/'], root: '../../'
end
