require 'net/http'
require 'nokogiri'
require 'csv'
require 'htmlentities'
require 'fileutils'
require_relative 'judgment'

class SLWCrawler
  SINGAPORE_LAW_WATCH_URL = 'http://www.singaporelawwatch.sg/slw/judgments.html'
  DOWNLOAD_DIR = 'crawled_judgments'
  INDEX_FILE_PATH = DOWNLOAD_DIR + '/index.csv'

  def self.serve_some_justice
    # make sure progress messages are shown immediately and not be bufferred
    STDOUT.sync = true

    print '[*] Fetching Singapore Law Watch website...'
    page_source =  self.fetch_website
    puts 'OK'

    print '[*] Scraping page source for judgments...'
    judgments = self.scrape_page_source_into_judgments(page_source)
    puts "found #{judgments.count} judgments"

    print '[*] Checking for new cases...'
    to_download = self.prune_downloaded_judgments(judgments)
    puts "#{to_download.count} new cases to download"

    if to_download.count > 0
      puts '[*] Downloading cases...'
      self.download_judgments(to_download)
    end

    puts '[*] Justice is served.'
  end

  def self.fetch_website
    uri = URI(SINGAPORE_LAW_WATCH_URL)
    response = Net::HTTP.get_response(uri)
    response.body
  end

  def self.scrape_page_source_into_judgments(page_source)
    html_doc = Nokogiri::HTML(page_source)
    judgment_nodes = html_doc.xpath('//ul[@id="judgments-list"]/li')

    judgments = Array.new
    judgment_nodes.each do |node|
      judgments << self.parse_node_into_judgment(node)
    end

    judgments
  end

  def self.prune_downloaded_judgments(judgments)
    # if no index file exists, there is nothing to be pruned
    return judgments unless self.has_index_file

    downloaded_judgments = self.get_downloaded_judgments()
    citations_of_downloaded_judgments = self.extract_array_of_citations(downloaded_judgments)

    new_judgments = judgments.select do |j|
      !citations_of_downloaded_judgments.include?(j[:neutral_citation])
    end

    new_judgments
  end

  def self.download_judgments(judgments)
    judgments = self.prune_downloaded_judgments(judgments)
    return if judgments.empty?

    self.create_directory_if_none_exist(DOWNLOAD_DIR)

    domain = 'www.singaporelawwatch.sg'

    Net::HTTP.start(domain) do |http|
      total = judgments.count
      judgments.each_with_index do |j, index|
        case_name_with_citation = "#{j.get_condensed_case_name}, #{j[:neutral_citation]}"
        puts "[==>] Downloading case [#{index+1}/#{total}]: #{case_name_with_citation}..."
        STDOUT.flush

        url = j[:url].to_s
        resource_path = url.slice(url.index('/slw')..-1)
        resp = http.get(resource_path)

        # replaces illegal characters \/:*?"<> with underscore
        filename = case_name_with_citation.gsub(/[\\\/:\*\?"<>|]/, '_') + '.pdf'
        open(DOWNLOAD_DIR + '/' + filename, 'wb') do |file|
          file.write(resp.body)
        end

        self.write_to_index_file(j)
      end
    end
  end

  def self.parse_node_into_judgment(node)
    Judgment.new(
      :case_name => self.get_case_name(node),
      :neutral_citation => self.get_neutral_citation(node),
      :decision_date => self.get_decision_date(node),
      :catchwords => self.get_catchwords(node),
      :url => self.get_url(node)
    )
  end

  def self.has_index_file
    File.exist?(INDEX_FILE_PATH)
  end

  def self.get_downloaded_judgments
    begin
      index = CSV.read(INDEX_FILE_PATH, :headers => true)
    rescue
      abort("Error opening index file. Please close and try againt")
    end

    downloaded_judgments = Array.new
    index.each do |csv_row|
      downloaded_judgments << Judgment.new(
        :case_name => csv_row['Case name'],
        :neutral_citation => csv_row['Neutral citation'],
        :decision_date => csv_row['Decision date'],
        :catchwords => csv_row['Catchwords']
      )
    end

    downloaded_judgments
  end

  def self.extract_array_of_citations(judgments)
    citations = Array.new
    judgments.each do |j|
      citations << j[:neutral_citation]
    end

    citations
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
    FileUtils.mkdir_p(directory_name) unless File.exist?(directory_name)
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
