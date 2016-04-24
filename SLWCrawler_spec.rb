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

  xit 'scrapes links to judgments' do
    response = SLWCrawler.fetch_website
    links = SLWCrawler.scrape_links(response)
    expect(links).not_to be_nil
    expect(links).not_to be_empty
  end

  it 'downloads judgements' do

  end

  it 'maintains index of download judgments and their categories' do

  end
end
