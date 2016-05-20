require 'sinatra'
require 'json'
require 'active_record'
require 'metafrazo'

require_relative 'models/blacklist'

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
class PullRequest < ActiveRecord::Base; end

Metafrazo.configure do |config|
  config.usernames = ["@mikekavouras"]
  config.token = ENV['TOKEN']
  config.repos = {
    "teespring/rails-teespring" => {
      compare_branch: "develop",
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

  if Metafrazo.run(json)
    # log_pr(pull_request)
    puts "*" * 80
    puts "changes have occured"
    puts "*" * 80
  else
    puts "*" * 80
    puts "NO changes have occured"
    puts "*" * 80
  end

  status 200
end

def notified_pr?(pr)
  PullRequest.where(number: pr["number"]).first
end

def log_pr(pr)
  PullRequest.create(number: pr["number"])
end
