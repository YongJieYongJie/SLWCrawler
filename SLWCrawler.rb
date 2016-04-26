require 'net/http'
require 'nokogiri'

class SLWCrawler
  def self.fetch_website
    uri = URI('http://www.singaporelawwatch.sg/slw/index.php/judgments')
    response = Net::HTTP.get_response(uri)
    response
  end

  def self.scrape_judgment_nodes(response)
    html_doc = Nokogiri::HTML(response)
    judgment_nodes = html_doc.xpath('//ul[@id="judgments-list"]/li')
    judgment_nodes
  end

  def self.download_judgment(node)
    url = self.get_url(node)
    case_name = self.get_case_name(node)

    domain = url.slice(url.index('//')+2..url.index('/slw')-1)
    resource_path = url.slice(url.index('/slw')..-1)

    puts "Downloading #{case_name}..."
    Net::HTTP.start(domain) do |http|
      resp = http.get(resource_path)

      # extract citation from original filename from server
      content_disposition = resp.to_hash['content-disposition'][0]
      citation = content_disposition.match(/filename="(.*)\.pdf"/)[0]

      open(case_name + '.pdf', 'wb') do |file|
        file.write(resp.body)
      end
    end
  end

  def self.get_url(node)
    node.xpath('a/@href').to_s
  end

  def self.get_case_name(node)
    node.xpath('a/text()').to_s.gsub('/', '-')
  end

  def self.generate_filename(node)

  end
end
