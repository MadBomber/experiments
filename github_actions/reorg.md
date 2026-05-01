Okay, I've analyzed the provided YAML and identified several areas where business logic can be extracted into Ruby scripts. Here's the reorganization:

**1. `bin` Scripts:**

**`bin/determine_target_environment.rb`:**

```ruby
#!/usr/bin/env ruby

merged = ENV['INPUT_MERGED']

target_environment = "development"
if merged == "true"
  target_environment = "production"
end

puts "target_environment=#{target_environment}"
```

**`bin/create_changed_files_list.rb`:**

```ruby
#!/usr/bin/env ruby

added_modified_renamed = ENV['INPUT_ADDED_MODIFIED_RENAMED']
renamed = ENV['INPUT_RENAMED']

if added_modified_renamed && !added_modified_renamed.empty?
  File.open("changed-files.txt", "w") do |file|
    added_modified_renamed.split.each do |f|
      file.puts f
    end
  end
end

if renamed && !renamed.empty?
  puts "rename_warning=TRUE"
end

puts "Expected files changes:"
if File.exist?("changed-files.txt")
  system("cat changed-files.txt")
else
  puts "No changed files found."
end
```

**`bin/get_bearer_token.rb`:**

```ruby
#!/usr/bin/env ruby
require 'open3'

lpb_host = ENV['LPB_HOST']
lpb_client_id = ENV['LPB_CLIENT_ID']
lpb_rsa_token = ENV['LPB_RSA_TOKEN']
okta_token_aud = ENV['OKTA_TOKEN_AUD']

File.write('./rsa.pem', lpb_rsa_token)

# Execute shell commands
puts "List files -la"
system("ls -la")
puts "Line Count rsa.pem"
system("wc -l ./rsa.pem")

stdout, stderr, status = Open3.capture3("node ./get-bearer-token.js #{lpb_client_id} ./rsa.pem #{lpb_host} #{okta_token_aud}")

if status.success?
    bearer_token = File.read('./bearer.token').strip
    puts "bearer_token=#{bearer_token}"
else
    puts "Error executing get-bearer-token.js: #{stderr}"
    exit 1
end
```

**`bin/send_content_to_lpb.rb`:**

```ruby
#!/usr/bin/env ruby
require 'open3'

lpb_host = ENV['LPB_HOST']
bearer_token = ENV['BEARER_TOKEN']

if !File.exist?("changed-files.txt")
    puts "changed-files.txt file does not exist. Exiting."
    exit 0;
end

File.readlines('changed-files.txt').each do |line|
  n = line.strip
  next unless n.include?('content/')

  puts "Posting #{n} to LPB"
  date_string = n.gsub(/[\/\.a-z\-]/, '').gsub(/(\d{4})(\d{2})(\d{2})/, '\1-\2-\3')
  content_string = `cat #{n} | base64 -w 0`.strip # Using backticks for command execution
  target_api = n.gsub(/.*\/([a-z\-]{1,})\/release-notes.*/, '\1')

  puts "Target URL https://#{lpb_host}/internal/platform-backend/v0/providers/#{target_api}/release-notes"

  command = "curl --request POST --header 'Content-Type:application/json' --header \"Authorization:Bearer #{bearer_token}\" --data '{\"date\":\"#{date_string}\",\"content\":\"base64:#{content_string}\"}' https://#{lpb_host}/internal/platform-backend/v0/providers/#{target_api}/release-notes"

  stdout, stderr, status = Open3.capture3(command)
  if !status.success?
      puts "Error posting to LPB: #{stderr}"
      exit 1
  end
  puts stdout
end
```

**`bin/get_urls_list.rb`:**

```ruby
#!/usr/bin/env ruby
require 'json'
require 'open-uri'

urls = ""

# Download legacy.json file
begin
  legacy_json_url = "https://developer.va.gov/platform-backend/v0/providers/transformations/legacy.json?environment=sandbox"
  legacy_json_content = URI.open(legacy_json_url).read
  legacy_data = JSON.parse(legacy_json_content)
rescue OpenURI::HTTPError => e
  puts "Error downloading legacy.json: #{e.message}"
  exit 1
rescue JSON::ParserError => e
  puts "Error parsing legacy.json: #{e.message}"
  exit 1
end

changed_files = File.exist?("changed-files.txt") ? File.readlines("changed-files.txt").map(&:strip) : []

changed_files.each do |n|
  next unless n.include?('content/') && n.include?('release-notes')

  target_api = n.gsub(/.*\/([a-z\-]{1,})\/release-notes.*/, '\1')
  target_api_name = nil
  target_url_slug = nil

  legacy_data.each do |item|
    item["apis"].each do |api|
      if api["altID"] == target_api || api["urlSlug"] == target_api
        target_api_name = api["name"]
        target_url_slug = api["urlSlug"]
        break
      end
    end
    break if target_api_name # Stop searching once found
  end

  if target_api_name && target_url_slug
    urls += "[#{target_api_name} release notes](https://developer.va.gov/explore/api/#{target_url_slug}/release-notes)\n"
  else
    puts "Warning: Could not find API name or URL slug for #{target_api}"
  end
end

puts "urls=#{urls}"
```

**2. Modified YAML File (`.github/workflows/example.yml`):**

```yaml
name: Post content to Lighthouse Platform Backend (LPB)
on:
  pull_request:
    types:
      - opened
      - synchronize
      - reopened
      - closed
    branches: [main]

jobs:
  gather_content:
    name: Gather the changed content
    runs-on: ubuntu-latest
    outputs:
      rename_warning: ${{ steps.create_files_list.outputs.rename_warning }}
      target_environment: ${{ steps.get_target_environment.outputs.target_environment }}
    steps:
      - name: Determine Target Environment
        id: get_target_environment
        run: |
          chmod +x ./bin/determine_target_environment.rb
          ./bin/determine_target_environment.rb
          TARGET_ENVIRONMENT=$(echo "$output" | grep "target_environment=" | cut -d '=' -f 2)
          echo "target_environment=$TARGET_ENVIRONMENT" >> $GITHUB_OUTPUT
        env:
          INPUT_MERGED: "${{ github.event.pull_request.merged }}"

      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - id: pr_files
        uses: Ana06/get-changed-files@v2.3.0
      - id: create_files_list
        name: Find files and send them
        continue-on-error: true
        run: |
          chmod +x ./bin/create_changed_files_list.rb
          ./bin/create_changed_files_list.rb > output.txt
          RENAME_WARNING=$(grep "rename_warning=" output.txt | cut -d '=' -f 2)
          echo "rename_warning=$RENAME_WARNING" >> $GITHUB_OUTPUT
        env:
          INPUT_ADDED_MODIFIED_RENAMED: "${{ steps.pr_files.outputs.added_modified_renamed }}"
          INPUT_RENAMED: "${{ steps.pr_files.outputs.renamed }}"
      - name: Save changed files list
        uses: actions/upload-artifact@v4
        with:
          name: changed-files
          path: changed-files.txt
  send_content_to_development:
    name: Send content to development LPB
    needs: [gather_content]
    environment:
      name: development
      url: https://dev-developer.va.gov
    runs-on: ubuntu-latest
    if: needs.gather_content.outputs.target_environment == 'development'
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: NPM install
        run: npm ci
      - id: get_bearer_token
        if: github.actor != 'dependabot[bot]'
        name: Get Bearer Token
        run: |
          chmod +x ./bin/get_bearer_token.rb
          ./bin/get_bearer_token.rb > output.txt
          BEARER_TOKEN=$(grep "bearer_token=" output.txt | cut -d '=' -f 2)
          echo "bearer_token=$BEARER_TOKEN" >> $GITHUB_ENV
        env:
          LPB_HOST: 'dev-api.va.gov'
          LPB_CLIENT_ID: ${{ secrets.LPB_CLIENT_ID }}
          LPB_RSA_TOKEN: ${{ secrets.LPB_RSA_SECRET }}
          OKTA_TOKEN_AUD: 'https://deptva-eval.okta.com/oauth2/ausg95zxf6dFPccy02p7/v1/token'

      - name: Get file list
        uses: actions/download-artifact@v4
        if: github.actor != 'dependabot[bot]'
        with:
          name: changed-files
      - name: Send content to development
        if: github.actor != 'dependabot[bot]'
        run: |
          chmod +x ./bin/send_content_to_lpb.rb
          ./bin/send_content_to_lpb.rb
        env:
          LPB_HOST: 'dev-api.va.gov'
          BEARER_TOKEN: ${{ env.bearer_token }}

      - name: Comment on PR
        uses: actions/github-script@v7
        if: github.actor != 'dependabot[bot]'
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: 'These changes have been pushed to [dev](https://dev-developer.va.gov/).'
            })
      - name: Previously Merged Warning Comment on PR
        uses: actions/github-script@v7
        if: |
          needs.gather_content.outputs.rename_warning == 'TRUE' &&
          github.actor != 'dependabot[bot]'
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: 'If this release note was merged to the `main` branch on another PR, you will need to reach out to [Team Okapi](https://lighthouseva.slack.com/archives/C01931CFMTQ) to remove the copy that remains on the previous date.'
            })
  send_content_to_production:
    name: Send content to production LPB
    needs: [gather_content]
    environment:
      name: production
      url: https://developer.va.gov
    runs-on: ubuntu-latest
    if: needs.gather_content.outputs.target_environment == 'production'
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: NPM install
        run: npm ci
      - id: get_bearer_token_production
        if: github.actor != 'dependabot[bot]'
        name: Get Bearer Token
        run: |
          chmod +x ./bin/get_bearer_token.rb
          ./bin/get_bearer_token.rb > output.txt
          BEARER_TOKEN=$(grep "bearer_token=" output.txt | cut -d '=' -f 2)
          echo "bearer_token=$BEARER_TOKEN" >> $GITHUB_ENV
        env:
          LPB_HOST: 'api.va.gov'
          LPB_CLIENT_ID: ${{ secrets.LPB_CLIENT_ID }}
          LPB_RSA_TOKEN: ${{ secrets.LPB_RSA_SECRET }}
          OKTA_TOKEN_AUD: 'https://va.okta.com/oauth2/ausdppulkgBFJDZZe297/v1/token'

      - name: Get file list
        uses: actions/download-artifact@v4
        if: github.actor != 'dependabot[bot]'
        with:
          name: changed-files
      - name: Send content to production
        env:
          LPB_HOST: 'api.va.gov'
        if: github.actor != 'dependabot[bot]'
        run: |
          chmod +x ./bin/send_content_to_lpb.rb
          ./bin/send_content_to_lpb.rb
        env:
          LPB_HOST: 'api.va.gov'
          BEARER_TOKEN: ${{ env.bearer_token }}

      - name: Comment on PR
        uses: actions/github-script@v7
        if: github.actor != 'dependabot[bot]'
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: 'These changes have been pushed to [production](https://developer.va.gov/).'
            })
  send_notifications:
    name: Send Slack notification for newly published release notes
    needs: [gather_content, send_content_to_production]
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Get file list
        uses: actions/download-artifact@v4
        if: github.actor != 'dependabot[bot]'
        with:
          name: changed-files
      - id: get_urls_list
        name: Get list of URLs with new release notes
        if: github.actor != 'dependabot[bot]'
        continue-on-error: true
        run: |
          chmod +x ./bin/get_urls_list.rb
          ./bin/get_urls_list.rb > output.txt
          URLS=$(grep "urls=" output.txt | cut -d '=' -f 2)
          echo "urls=$URLS" >> $GITHUB_OUTPUT
      - name: Send Slack notification on success
        if: github.actor != 'dependabot[bot]' && success()
        uses: slackapi/slack-github-action@v2
        with:
          method: chat.postMessage
          token: ${{ secrets.SLACK_BOT_TOKEN }}
          payload: |
            # This ID is for #team-marmoset-alerts in Lighthouse Slack
            channel: C02B97B1WUR
            text: "Developer Portal Content Update"
            blocks:
              - type: "section"
                text:
                  type: "mrkdwn"
                  text: "A new release note has been posted to the developer portal. Please see the following links:"
              - type: "section"
                text:
                  type: "mrkdwn"
                  text: "${{ steps.get_urls_list.outputs.urls }}"
      - id: send_slack_failure_message
        if: github.actor != 'dependabot[bot]' && failure()
        uses: slackapi/slack-github-action@v2
        with:
          method: chat.postMessage
          token: ${{ secrets.SLACK_BOT_TOKEN }}
          payload: |
            # This ID is for #team-okapi-alerts in Lighthouse Slack
            channel: C05HL4MTAFR
            text: "Developer Portal Content Slack Notification Failure"
            blocks:
              - type: "section"
                text:
                  type: "mrkdwn"
                  text: "The Marmoset Release Note alert failed in the Developer Portal Content repository."
              - type: "section"
                text:
                  type: "mrkdwn"
                  text: "@teamokapi please investigate."
```

**Key Improvements and Explanations:**

*   **Decoupling:**  The core logic is now in Ruby scripts.  The YAML is primarily configuration and orchestration.

*   **Environment Variables:** Inputs to the scripts are passed via environment variables.  This makes the scripts much easier to test.

*   **Output Capture:** The `puts "variable=value"` pattern in the Ruby scripts, along with the `grep` and `cut` commands in the YAML, is used to capture output from the scripts and set GitHub Actions output variables or environment variables. This is crucial for passing data between steps.  Note, to make it easier I have changed all output capture to write out to a temp file named output.txt and parse that for the expected output in the YAML file.  This makes it easier for the scripts not to worry about formatting.

*   **Error Handling:** Basic error handling (exiting with a non-zero status code) is included in the Ruby scripts.

*   **Readability:** The YAML file is now much cleaner and easier to understand.

*   **Testability:** The Ruby scripts can be tested in isolation using RSpec or Minitest.

**Next Steps:**

1.  **Create the `bin` directory** in your repository's root.
2.  **Copy the script files** into the `bin` directory.
3.  **Make the scripts executable:**  `chmod +x bin/*.rb`
4.  **Update your `.github/workflows/example.yml` file** with the modified YAML provided above.
5.  **Test the workflow** in your GitHub repository.
6.  **Write RSpec/Minitest tests** for the Ruby scripts to thoroughly test the logic.

Remember that you might need to adjust the scripts and YAML based on your specific requirements and testing scenarios. Good luck!
