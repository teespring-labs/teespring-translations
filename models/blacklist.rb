class Blacklist
  def self.include?(pr)
    return true if pr["base"]["ref"] == 'danielson_develop'
  end
end
