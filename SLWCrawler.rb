require 'net/http'
require 'nokogiri'

class SLWCrawler
  def self.fetch_website
    uri = URI('http://www.singaporelawwatch.sg/slw/index.php/judgments')
    response = Net::HTTP.get_response(uri)
    response
  end

  def self.scrape_links(response)
    html_doc = Nokogiri::HTML(response)
    judgments = html_doc.xpath('//ul[@id="judgments-list"]/li')
  end
end
