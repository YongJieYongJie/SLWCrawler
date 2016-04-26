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

  it 'scrapes nodes containing individual judgments' do
    VCR.use_cassette('fetch_website') do
      response = SLWCrawler.fetch_website
      nodes = SLWCrawler.scrape_judgment_nodes(response.body)
      expect(nodes).not_to be_nil
    end
  end

  it 'downloads judgements' do
    VCR.use_cassette('fetch_website') do
      response = SLWCrawler.fetch_website
      nodes = SLWCrawler.scrape_judgment_nodes(response.body)
      nodes.each { |n| SLWCrawler.download_judgment(n) }
    end
  end

  it 'maintains index of download judgments and their categories' do

  end
end
