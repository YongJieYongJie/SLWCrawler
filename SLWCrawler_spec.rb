require 'vcr'
require 'vcr_helper'
require_relative 'SLWCrawler'

describe SLWCrawler do
  it 'fetches SLW website' do
    VCR.use_cassette('fetch_website') do
      page_source = SLWCrawler.fetch_website
      expect(page_source).to include('<ul id="judgments-list">')
    end
  end

  it 'scrapes page source into an array of judgments' do
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
      judgments = SLWCrawler.scrape_page_source_into_judgments(website_source)
      expect(judgments.count).to eq(2)
    end
  end

  it 'prunes existing judgments' do
    existing_judgments = [{
      :case_name => 'Lee Han Min Garry v Piong Michelle Lucia',
      :neutral_citation => '[2016] SGHC 79',
      :url => 'http://www.singaporelawwatch.sg/slw/index.php/component/cck/?task=download&amp;file=attached_document&amp;id=80783&amp;utm_source=web%20subscription&amp;utm_medium=web&amp;src=judgments'
    }]

    fetched_judgments = [{
      :case_name => 'Lee Han Min Garry v Piong Michelle Lucia',
      :neutral_citation => '[2016] SGHC 79',
      :url => 'http://www.singaporelawwatch.sg/slw/index.php/component/cck/?task=download&amp;file=attached_document&amp;id=80783&amp;utm_source=web%20subscription&amp;utm_medium=web&amp;src=judgments'
    },
    {
      :case_name => 'Maniach Pte Ltd v L Capital Jones Ltd and another',
      :neutral_citation => '[2016] SGHC 65',
      :url => 'http://www.singaporelawwatch.sg/slw/index.php/component/cck/?task=download&amp;file=attached_document&amp;id=80782&amp;utm_source=web%20subscription&amp;utm_medium=web&amp;src=judgments'
    }]

    allow(SLWCrawler).to receive(:get_downloaded_judgments) { existing_judgments }
    pruned_judgments = SLWCrawler.prune_downloaded_judgments(fetched_judgments)

    expect(pruned_judgments.count).to eq(1)
  end

  it 'maintains index of download judgments and their categories' do

  end
end
