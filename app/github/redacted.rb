require 'net/http'
require 'base64'

module Github
  class Redacted
    def self.process_request(request)
      redactions = []

      # If we have a 'redact' query param, parse the redactions array
      if (redact = request.params['redact'])
        redactions = Base64.decode64(redact).split(',')
      end

      path = request.fullpath

      # If the root seems base64 encoded, decode it before passing to github
      _, root_path, = request.path.split('/')
      if root_path
        decoded_root = Base64.decode64(root_path)

        if decoded_root.ascii_only?
          path = path.gsub(/#{root_path}/, decoded_root)
        end
      end

      github_uri = URI("https://github.com#{path}")
      STDERR.puts "    FORWARDING #{request.path} -> #{github_uri}"

      # These styles hide some identifying data, like the user's avatar
      injected_styles = <<-CSS
        <style>
          .commit-tease,
          .user-profile-mini-avatar,
          .avatar,
          .vcard-details,
          .signup-prompt-bg {
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

      # We want to fetch the relevant path on github,
      # eventually probably should have some error handling.
      response = Net::HTTP.get(github_uri)

      response = response.gsub(%r{</head>}, "#{injected_styles} #{injected_script} \\0")
      response = response.gsub(%r{<meta property="og:image" content="(.*?)" />}, '')
      redactions.each { |redaction|
        response = response.gsub(%r{/#{redaction}}, "/#{Base64.strict_encode64(redaction)}")
        response = response.gsub(%r{#{redaction}}, '[redacted]')
      }

      ['200', {'Content-Type' => 'text/html'}, [ response ]]
    end
  end
end
