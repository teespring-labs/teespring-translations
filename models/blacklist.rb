class Blacklist
  def self.include?(pr)
    return true if pr["base"]["ref"] == 'danielson_develop'
    return true if pr["head"]["ref"].downcase.match("i18n") != nil
  end
end
