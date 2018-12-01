unless ENV['RACK_ENV'] == 'production'
  use Rack::Reloader, 0
end

require './app.rb'
run App.new
