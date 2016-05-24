require 'sidekiq'

class PullRequestWorker
  include Sidekiq::Worker

  def perform(json)
    puts "*" * 80
    puts "performing..."
    puts "*" * 80
    if Metafrazo.run(json)
      PullRequest.create(number: json["pull_request"]["number"])
    end
  end

end
