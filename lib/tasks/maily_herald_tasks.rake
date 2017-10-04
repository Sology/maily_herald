namespace :maily_herald do
  namespace :doc do
    desc 'Generate API documentation'
    task :api => :environment do
      api_file_path = File.join(File.dirname(__FILE__), '../../doc/api/v1/api.yaml')
      api_docs_dest = File.join(File.dirname(__FILE__), '../../doc/api/v1/')
      sh "bootprint openapi #{api_file_path} #{api_docs_dest}"
    end
  end
end
