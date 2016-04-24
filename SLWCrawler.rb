require 'net/http'

class SLWCrawler
  def self.fetch_website
    uri = URI('http://www.singaporelawwatch.sg/slw/index.php/judgments')
    response = Net::HTTP.get_response(uri)
    response
  end

  def self.scrape_links(response)

  end
end
