require 'vcr'
require 'vcr_helper'
require_relative 'SLWCrawler'

describe SLWCrawler do
  it 'fetches SLW website' do
    VCR.use_cassette('fetch_website') do
      response = SLWCrawler.fetch_website
      expect(response.code.to_i).to eq(200)
    end
  end

  it 'scrapes website into array of judgments' do
    VCR.use_cassette('fetch_website') do
      response = SLWCrawler.fetch_website
      judgments = SLWCrawler.scrape_into_judgments(response.body)
      puts judgments.inspect
      expect(judgments).not_to be_nil
    end
  end

  xit 'downloads judgements' do
    VCR.use_cassette('fetch_website') do
      response = SLWCrawler.fetch_website
      nodes = SLWCrawler.scrape_judgment_nodes(response.body)
      nodes.each { |n| SLWCrawler.download_judgment(n) }
    end
  end

  it 'maintains index of download judgments and their categories' do

  end
end
