require './app/github/redacted.rb'
require './app/index.rb'

class App
  def call(env)
    req = Rack::Request.new(env)
    case req.path_info
    when '/'
      Index.process_request(req)
    else
      ## Here we do the meat of things, pass-through to a redacted github
      Github::Redacted.process_request(req)
    end
  end
end
