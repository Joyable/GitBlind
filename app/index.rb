class Index
  GITHUB_REPO = 'https://github.com/joyable/gitblind'

  def self.process_request(request)

    styles = <<-CSS
      body {
        font-family: Arial, sans-serif;
        font-size: 16px;
      }
      .formGroup {
        margin-bottom: 5px;
      }
      label {
        display: inline-block;
        margin-bottom: 5px;
        font-weight: bold;
      }
      .wrapper {
        max-width: 1000px;
        padding: 15px;
        margin: auto;
      }
      .formHelp {
        color: #868e96;
        display: block;
        margin-bottom: 5px;
        font-size: smaller;
      }
      .formControl {
        display: inline-block;
        width: 100%;
        padding: 5px;
        font-size: 15px;
        line-height: 1.25;
        color: #495057;
        background-color: #fff;
        background-image: none;
        background-clip: padding-box;
        border: 1px solid rgba(0,0,0,.15);
        border-radius: 5px;
        transition: border-color ease-in-out .15s,box-shadow ease-in-out .15s;
        margin-bottom: 25px;
      }
      button {
        color: #fff;
        background-color: #294282;
        display: inline-block;
        font-weight: bold;
        font-size: 16px;
        text-align: center;
        border: 1px solid #fff;
        padding: 10px;
        line-height: 1.25;
        border-radius: 5px;
        transition: all .15s ease-in-out;
      }
    CSS

    script = <<-JS
      function generateLink() {
        const username = document.querySelector('#username').value;
        const name = document.querySelector('#name').value;
        const additionalKeywords = document.querySelector('#additionalKeywords').value;

        const redact = `${username},${name},${name.split(' ').join(',')},${additionalKeywords.replace(', ', ',')}`;

        const url = `${window.location.origin}/${btoa(username)}?redact=${btoa(redact)}`
        document.querySelector('.redactedLink').innerHTML = `
          <h2>Blind link:</h2>
          <a href='${url}'>${url}</a>
        `;
      }
    JS

    response = <<-HTML
      <!DOCTYPE html>
      <html>
        <head>
          <style>#{styles}</style>
          <script>#{script}</script>
          <title>Git Blind</title>
        </head>
        <body>
          <div class='wrapper'>
            <div class='header'>
              <h1>Git Blind</h1>
              <div class='intro'>
                <p>Git blind is a tool to help you review applicants github profile with reduced bias.</p>
                <p>
                  Code and documentation:
                  <a href='#{GITHUB_REPO}'>#{GITHUB_REPO}</a>
                </p>
              </div>
            </div>
            <div class='generateLinkForm'>
              <h2>Create a redacted GitHub link</h2>
              <div class='formGroup'>
                <label for='username'>Github Username:</label>
                <div id="usernameHelp" class="formHelp">
                  The username for the GitHub user you want to anonymize.
                </div>
                <input type='text' class='formControl' name='username' id='username' placeholder='Imperiopolis' />
              </div>
              <div class='formGroup'>
                <label for='name'>Applicant Name:</label>
                <div id="nameHelp" class="formHelp">
                  The full name of the applicant you want to anonymize.
                </div>
                <input type='text' class='formControl' name='name' id='name' placeholder='Nora Trapp' />
              </div>
              <div class='formGroup'>
                <label for='additionalKeywords'>Additional keywords:</label>
                <div id="additionalKeywordsHelp" class="formHelp">
                  Any additional keywords you wish to anonymize, comma separated. For example, this could include the applicant's nicknames or employer.
                </div>
                <textarea id='additionalKeywords' class='formControl' name='additionalKeywords' placeholder='Joyable, Some Other Thing'></textarea>
              </div>
              <button type='submit' onclick='generateLink()'>Generate Link</button>
            </div>
            <div class='redactedLink'/>
          </div>
        </body>
      </html>
    HTML

    [200, {"Content-Type" => "text/html"}, [response]]
  end
end
