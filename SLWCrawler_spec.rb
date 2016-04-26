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
      website_source = %(
<ul id="judgments-list">
  <li>
    <span id="catchwords">
      Insolvency law — Bankruptcy
    </span>
    <br>
    <a href="http://www.singaporelawwatch.sg/slw/index.php/component/cck/?task=download&amp;file=attached_document&amp;id=80783&amp;utm_source=web%20subscription&amp;utm_medium=web&amp;src=judgments">
      Lee Han Min Garry v Piong Michelle Lucia
    </a>
    <br>
    <span id="link-pdf">
      [2016] SGHC 79 |   Decision Date: 21 Apr 2016
    </span>
  </li>
  <li>
    <span id="catchwords">
      Arbitration — Agreement, Arbitration — Arbitrability and public policy, Arbitration — Stay of court proceedings
    </span>
    <br>
    <a href="http://www.singaporelawwatch.sg/slw/index.php/component/cck/?task=download&amp;file=attached_document&amp;id=80782&amp;utm_source=web%20subscription&amp;utm_medium=web&amp;src=judgments">
      Maniach Pte Ltd v L Capital Jones Ltd and another
    </a>
    <br>
    <span id="link-pdf">
      [2016] SGHC 65 |   Decision Date: 26 Apr 2016
    </span>
  </li>
</ul>
)
      judgments = SLWCrawler.scrape_into_judgments(website_source)
      expect(judgments.count).to eq(2)
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
