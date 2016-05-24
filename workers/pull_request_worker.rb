require 'sidekiq'

class PullRequestWorker
  include Sidekiq::Worker

  def perform(json)
    puts "*" * 80
    puts "performing..."
    puts "*" * 80
    if Metafrazo.run(json)
      puts "*" * 80
      puts "found some changes..."
      puts "*" * 80
      PullRequest.create(number: json["pull_request"]["number"])
    end
  end

end
