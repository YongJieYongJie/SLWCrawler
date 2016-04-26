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

  def self.download_judgments(judgments)
    domain = 'www.singaporelawwatch.sg'

    Net::HTTP.start(domain) do |http|
      judgments.each do |j|
        puts "Downloading #{j[:case_name]}..."
        STDOUT.flush

        url = j[:url].to_s
        resource_path = url.slice(url.index('/slw')..-1)
        resp = http.get(resource_path)

        open(j.generate_filename, 'wb') do |file|
          file.write(resp.body)
        end
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
