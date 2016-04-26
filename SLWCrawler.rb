require 'net/http'
require 'nokogiri'
require_relative 'judgment'

class SLWCrawler
  def self.fetch_website
    uri = URI('http://www.singaporelawwatch.sg/slw/index.php/judgments')
    response = Net::HTTP.get_response(uri)
    response
  end

  def self.scrape_into_judgments(response)
    html_doc = Nokogiri::HTML(response)
    judgment_nodes = html_doc.xpath('//ul[@id="judgments-list"]/li')

    judgments = Array.new
    judgment_nodes.each do |node|
      judgments << Judgment.new(
        :case_name => self.get_case_name(node),
        :neutral_citation => self.get_neutral_citation(node),
        :decision_date => self.get_decision_date(node),
        :catchwords => self.get_catchwords(node),
        :url => self.get_url(node)
      )
    end
    judgments
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

  def self.get_case_name(node)
    node.at_xpath('a/text()').to_s
  end

  def self.get_neutral_citation(node)
    node.at_xpath('span[@id="link-pdf"]/text()').to_s.match(/^(.*) \|/)[1]
  end

  def self.get_decision_date(node)
    node.at_xpath('span[@id="link-pdf"]/text()').to_s.match(/Decision Date: (.*)/)[1]
  end

  def self.get_catchwords(node)
    node.at_xpath('span[@id="catchwords"]/text()').to_s
  end

  def self.get_url(node)
    node.at_xpath('a/@href').to_s
  end
end
