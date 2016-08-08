require 'sidekiq'

class PullRequestWorker
  include Sidekiq::Worker

  def perform(json)
    if Metafrazo.run(json)
      PullRequest.create(number: json["pull_request"]["number"])
    end
  end

end
