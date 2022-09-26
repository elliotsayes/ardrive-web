opt_out_usage

# Get project root
def root_path
  Dir.pwd.sub(/.*\Kfastlane/, '').sub(/.*\Kandroid/, '').sub(/.*\Kios/, '').sub(/.*\K\/\//, '')
end

# Create Firebase release URL
def get_firebase_release_url (release_name, app)
  release_base_url = "https://appdistribution.firebase.google.com/testerapps/"
  release_id_path = release_name.split(app).last

  return release_base_url + app + release_id_path
end

# Run on root
lane :sh_on_root do |options|
  command = options[:command]

  sh("cd #{root_path} && #{command}")
end

# Reusable tasks
lane :fetch_dependencies do
  sh_on_root(command: "flutter clean")
  sh_on_root(command: "flutter pub get")
end

lane :build_autogenerated_code do
  sh_on_root(command: "flutter pub run build_runner build --delete-conflicting-outputs")
end

lane :update_pr_and_jira do |options|
  release_url = options[:release_url]
  ios = options[:ios]
  platform = if ios then "iOS" else "Android" end
  pr_number = ENV['PR_NUMBER']
  pr_title = ENV['PR_TITLE']
  pr_body = get_github_pr_description(pr_number)
  git_sha = ENV['GIT_SHA']
  build_number = ENV['BUILD_NUMBER']
  jira_ticket = pr_title.split(':').first

  # Add releases header if it doesn't exists
  releases_header = "--- Releases ---"
  if not pr_body.include? releases_header
    pr_body += "\n\n" + releases_header
  end

  # Add or update release field
  release_field = platform + " release: "
  release_text = release_field + release_url
  if not pr_body.include? release_field
    pr_body += "\n" + release_text
  else
    pr_body = pr_body.gsub(/^.*#{release_field}.*$/, release_text)
  end

  github_api(
    api_bearer: ENV["GITHUB_TOKEN"],
    http_method: "PATCH",
    path: "/repos/ardriveapp/ardrive-web/pulls/#{pr_number}",
    body: { body: pr_body }
  )

  jira(
    ticket_id: jira_ticket,
    comment_text: "New #{platform} release! \nBuild number: #{build_number}\nGit sha: #{git_sha}\nURL: #{release_url}"
  )

end

def get_github_pr_description (pr_number)
  require 'net/http'
  require 'json'

  github_token = ENV['GITHUB_TOKEN']
  uri = URI("https://api.github.com/repos/ardriveapp/ardrive-web/pulls/#{pr_number}")
  headers = {
    'Accept': 'application/vnd.github+json',
    'Authorization': "Bearer #{github_token}"
  }

  request = Net::HTTP::Get.new(uri, headers)
  response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) do |http|
    http.request(request)
  end

  response_body = JSON.parse(response.body)

  return response_body["body"]
end