RSpec.configure do |config|
  config.around do |example|
    case example.metadata[:database]
    when :postgres
      example.run if ENV["DB"] == "postgres"
    when :mysql
      example.run if ENV["DB"] == "mysql"
    when :sqlite
      example.run if ENV["DB"] == "sqlite"
    else
      example.run
    end
  end
end
