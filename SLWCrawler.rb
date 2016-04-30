require 'net/http'
require 'nokogiri'
require 'csv'
require 'HTMLEntities'
require_relative 'judgment'

class SLWCrawler
  DOWNLOAD_DIR = 'downloaded_cases'
  INDEX_FILE_PATH = DOWNLOAD_DIR + '/index.csv'

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
    judgments = self.prune_already_downloaded_judgments(judgments)
    return if judgments.empty?

    self.create_directory_if_none_exist(DOWNLOAD_DIR)

    domain = 'www.singaporelawwatch.sg'

    Net::HTTP.start(domain) do |http|
      judgments.each do |j|
        puts "Downloading #{j.get_condensed_case_name}..."
        STDOUT.flush

        url = j[:url].to_s
        resource_path = url.slice(url.index('/slw')..-1)
        resp = http.get(resource_path)

        # replaces illegal characters \/:*?"<> with underscore
        filename = j.get_condensed_case_name.gsub(/[\\\/:\*\?"<>|]/, '_')
        open(DOWNLOAD_DIR + '/' + filename, 'wb') do |file|
          file.write(resp.body)
        end

        self.write_to_index_file(j)
      end
    end
  end

  def self.prune_already_downloaded_judgments(judgments)
    # if no index file exists, there is nothing to be pruned
    return judgments unless self.has_index_file

    begin
      index = CSV.read(INDEX_FILE_PATH).flatten
    rescue
      abort("Error opening index file. Please close and try againt")
    end

    remaining_judgments = judgments.select { |j| !index.include?(j[:neutral_citation]) }
    remaining_judgments
  end

  def self.has_index_file
    File.exist?(INDEX_FILE_PATH)
  end

  def self.write_to_index_file(judgment)
    self.create_directory_if_none_exist(DOWNLOAD_DIR)

    # create new index file with header row if none exist previously
    if (!self.has_index_file)
      begin
        CSV.open(INDEX_FILE_PATH, 'w') do |csv|
          csv << ['Case name', 'Condensed case name', 'Neutral citation', 'Decision date', 'Catchwords']
        end
      rescue
        abort("Error creating index file. Please try again.")
      end
    end

    begin
      CSV.open(INDEX_FILE_PATH, 'a') do |csv|
        csv << [judgment[:case_name], judgment.get_condensed_case_name, judgment[:neutral_citation], judgment[:decision_date], judgment[:catchwords]]
      end
    rescue
      abort("Error writing to index file. Please try again.")
    end
  end

  def self.create_directory_if_none_exist(directory_name)
    Dir.mkdir(directory_name) unless File.exist?(directory_name)
  end

  def self.get_case_name(node)
    HTMLEntities.new.decode(node.at_xpath('a/text()').to_s)
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
