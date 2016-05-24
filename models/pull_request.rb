class PullRequest < ActiveRecord::Base;
  validates :number, uniqueness: true
end
