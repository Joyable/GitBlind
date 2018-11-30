require 'socket'
require 'net/http'
require 'base64'
require 'cgi'

# Initialize a TCPServer object that will listen
# on localhost:2345 for incoming connections.
server = TCPServer.new('0.0.0.0', ENV['PORT'] || 2345)

# loop infinitely, processing one incoming
# connection at a time.
loop do

  # Wait until a client connects, then return a TCPSocket
  # that can be used in a similar fashion to other Ruby
  # I/O objects. (In fact, TCPSocket is a subclass of IO.)
  socket = server.accept

  # Read the first line of the request (the Request-Line)
  request = socket.gets

  next unless request

  # Log the request to the console for debugging
  STDERR.puts request

  _, raw_path = request.split(' ')
  path = raw_path

  _, query_string = path.split('?')

  redactions = {}

  # If we have a 'redact' query param, swap out any redacted strings
  # in the path before passing to github.
  if query_string &&
     (parsed_query = CGI::parse(query_string)) &&
     (redact = parsed_query['redact']) &&
     redact.any?

    redactions = Base64.decode64(redact[0]).split(',')
    redactions.each do |redaction|
      path = path.gsub(/#{Base64.strict_encode64(redaction)}/, redaction)
    end
  end

  github_uri = URI("https://github.com#{path}")

  STDERR.puts "    FORWARDING #{raw_path} -> #{github_uri}"

  # We want to fetch the relevant path on github,
  # eventually probably should have some error handling.
  response = Net::HTTP.get(github_uri)

  # These styles hide some identifying data, like the user's avatar
  injected_styles = <<-CSS
    <style>
      .user-profile-mini-avatar, .avatar {
        display: none !IMPORTANT;
      }
      .vcard-details {
        display: none !IMPORTANT;
      }
    </style>
  CSS

  # This script maintains the 'redact' query param when navigating about
  injected_script = <<-JS
    <script>
      document.addEventListener('DOMContentLoaded', function() {
        this.querySelectorAll('a').forEach(anchor => {
          anchor.addEventListener('click', e => {
            e.preventDefault();

            const redact = new URLSearchParams(window.location.search).get('redact');
            const hasExistingParams = anchor.href.includes('?');
            window.location.href = anchor.href + (hasExistingParams ? `&redact=${redact}` : `?redact=${redact}`);
          });
        });
      });
    </script>
  JS

  response = response.gsub(%r{</head>}, "#{injected_styles} #{injected_script} \\0")
  response = response.gsub(%r{<meta property="og:image" content="(.*?)" />}, '')
  redactions.each { |redaction|
    response = response.gsub(%r{/#{redaction}}, "/#{Base64.strict_encode64(redaction)}")
    response = response.gsub(%r{#{redaction}}, '[redacted]')
  }

  # We need to include the Content-Type and Content-Length headers
  # to let the client know the size and type of data
  # contained in the response. Note that HTTP is whitespace
  # sensitive, and expects each header line to end with CRLF (i.e. "\r\n")
  socket.print "HTTP/1.1 200 OK\r\n" +
               "Content-Type: text/html\r\n" +
               "Content-Length: #{response.bytesize}\r\n" +
               "Connection: close\r\n"

  # Print a blank line to separate the header from the response body,
  # as required by the protocol.
  socket.print "\r\n"

  # Print the actual response body, which is just "Hello World!\n"
  socket.print response

  # Close the socket, terminating the connection
  socket.close
end
