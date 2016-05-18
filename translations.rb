require 'sinatra'
require 'json'

$locales_path = "config/locales"

get '/' do
  "Hello, world!"
end

post '/payload' do

  pr = fetch_and_parse_json
  diff = run_diff(pr)
  locales = diff.select { |d| d.include? $locales_path }
  comment(message) unless locales.empty?

  status 200
end

def comment(message)
  messages = [
    "ci sono nuove stringhe que sono in disperato bisogno di traduzione",
    "hay nuevas cadenas que están en desesperada necesidad de la traducción",
    "Que há novas cordas estão em necessidade desesperada de tradução",
    "il y a des nouvelles chaînes Que sont dans le besoin désespéré de la traduction",
    "gibt es neue Saiten que sind in einer verzweifelten Notwendigkeit Übersetzung"
  ]
  message = "@mikekavouras: #{messages.sample}"
  `curl "https://api.github.com/repos/teespring/rails-teespring/issues/#{pr["number"]}/comments" -u #{ENV['USERNAME']}:#{ENV['TOKEN']} -d '{"body":"#{message}"}'`
end

def fetch_and_parse_json
  JSON.parse(request.body.read)["pull_request"]
end

def run_diff(pr)
  sha = pr["head"]["sha"]
  "#{`./scripts/run_da_diff #{sha} #{ENV['TOKEN']}`}".split("\n")
end
