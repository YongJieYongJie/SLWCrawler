require 'net/http'
require 'nokogiri'
require 'csv'
require_relative 'judgment'

class SLWCrawler
  DOWNLOAD_DIR = 'downloaded_cases'
  INDEX_PATH = 'downloaded_cases.csv'

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
    self.create_directory_if_none_exist(DOWNLOAD_DIR)

    domain = 'www.singaporelawwatch.sg'

    Net::HTTP.start(domain) do |http|
      judgments.each do |j|
        puts "Downloading #{j[:case_name]}..."
        STDOUT.flush

        url = j[:url].to_s
        resource_path = url.slice(url.index('/slw')..-1)
        resp = http.get(resource_path)

        open(DOWNLOAD_DIR + '/' + j.generate_filename, 'wb') do |file|
          file.write(resp.body)
        end

        self.write_to_index_file(j)
      end
    end
  end

  def self.write_to_index_file(judgment)
    CSV.open(INDEX_PATH, 'a') do |csv|
      csv << [judgment[:case_name], judgment[:neutral_citation], judgment[:decision_date], judgment[:catchwords]]
    end
  end

  def self.create_directory_if_none_exist(directory_name)
    Dir.mkdir(directory_name) unless File.exist?(directory_name)
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
