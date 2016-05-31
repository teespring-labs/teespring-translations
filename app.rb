require 'sinatra'
require 'json'
require 'active_record'
require 'metafrazo'
require 'sidekiq'

require_relative 'models/blacklist'
require_relative 'models/pull_request'
require_relative 'workers/pull_request_worker'

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

Metafrazo.configure do |config|
  config.usernames = ["@mikekavouras", "@kndrybecky"]
  config.token = ENV['TOKEN']
  config.repos = {
    "teespring/rails-teespring" => {
      base_branch: "develop",
      path: "config/locales"
    },
    "teespring/composer" => {
      path: "src/locales"
    },
    "teespring/direct-composer" => {
      path: "src/locales"
    }
  }
end

Sidekiq.configure_client do |config|
  config.redis = { size: 27, db: 1 }
end

Sidekiq.configure_server do |config|
  config.redis = { size: 27, db: 1 }
end

get '/' do
  "Hello, 👊!"
end

# rails teespring
post '/:repo' do
  json = JSON.parse(request.body.read)
  pull_request = json["pull_request"]

  halt 200 if Blacklist.include?(pull_request)
  halt 200 if notified_pr?(pull_request)
  halt 200 if json["action"] == 'labeled'

  PullRequestWorker.perform_async(json)

  status 200
end

def notified_pr?(pr)
  PullRequest.where(number: pr["number"]).first
end
