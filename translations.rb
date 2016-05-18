require 'sinatra'
require 'json'

$locales_path = "config/locales"
$usernames = ["@mikekavouras"]
$filename = "pull_requests.json"

get '/' do
  "Hello, world!"
end

# rails teespring
post '/rt-payload' do
  run_the_stuff('rails-teespring')
end

# composer
post '/c-payload' do
  run_the_stuff('composer')
end

# direct-composer
post '/dc-payload' do
  run_the_stuff('direct-composer')
end

def run_the_stuff(repo)
  json = JSON.parse(request.body.read)
  pr = json["pull_request"]

  halt 200 if has_already_notified_pr?(pr)
  halt 200 if payload_action_is?(json, 'labeled')

  diff = check_diff(pr, repo)
  locales = diff.select { |d| d.include? $locales_path }

  unless locales.empty?
    post_comment(pr, repo, locales) unless locales.empty?
    post_label(pr, repo) unless locales.empty?
    log_pr_notified(pr)
  end

  status 200
end

def has_already_notified_pr?(pr)
  return false unless File.exists?($filename)

  file = File.read($filename)
  arr = JSON.parse(file)
  arr.include?(pr["number"].to_s)
end

def log_pr_notified(pr)
  File.new($filename, "w+") unless File.exists?($filename)
  file = File.read($filename)

  arr = JSON.parse(file) rescue []
  arr << pr["number"].to_s

  File.open($filename, "r+") { |f| f.write(arr.to_json) }
end

def post_comment(pr, repo, locales)
  message = format_message(locales)
  puts "*** posting comment ***"
  `curl "https://api.github.com/repos/teespring/#{repo}/issues/#{pr["number"]}/comments" -u #{ENV['USERNAME']}:#{ENV['TOKEN']} -d '{"body":"#{message}"}'`
  puts "*** finished posting comment ***"
end

def post_label(pr, repo)
  puts "*** posting label ***"
  `curl "https://api.github.com/repos/teespring/#{repo}/issues/#{pr["number"]}/labels" -u #{ENV['USERNAME']}:#{ENV['TOKEN']} -d '["Translations"]'`
  puts "*** finished posting label ***"
end

def payload_action_is?(payload, action)
  payload["action"] == action
end

def format_message(locales)
  messages = [
    "ci sono nuove stringhe que sono in disperato bisogno di traduzione",
    "hay nuevas cadenas que están en desesperada necesidad de la traducción",
    "Que há novas cordas estão em necessidade desesperada de tradução",
    "il y a des nouvelles chaînes Que sont dans le besoin désespéré de la traduction",
    "gibt es neue Saiten que sind in einer verzweifelten Notwendigkeit Übersetzung"
  ]
  message = "#{$usernames.join(' ')}: #{messages.sample}: "
  message += locales.map { |locale| "`#{locale}`" }.join(' ')
end

def check_diff(pr, repo)
  master_branch = repo == 'rails-teespring' ? 'develop' : 'master'
  sha = pr["head"]["sha"]
  "#{`./scripts/run_da_diff #{sha} #{ENV['TOKEN']} #{repo} #{master_branch}`}".split("\n")
end
