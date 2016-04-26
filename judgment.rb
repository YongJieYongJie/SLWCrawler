Judgment = Struct.new(:case_name, :neutral_citation, :decision_date, :catchwords, :url) do
  def initialize(args)
	super(*args.values_at(:case_name, :neutral_citation, :decision_date, :catchwords, :url))
  end

  def generate_filename
	# replaces illegal characters \/:*?"<> with underscore
	sanitized_case_name = case_name.to_s.gsub(/[\\\/:\*\?"<>|]/, '_') 
	condensed_case_name = sanitized_case_name.gsub(/( and another( suit| matter| appeal)?| and others)/i, '')
    condensed_case_name.gsub!(/ private limited| pte limited| pte ltd| pvt ltd| limited| ltd/i, '')
    condensed_case_name.gsub!(/public prosecutor/i, 'PP')
    condensed_case_name.gsub!(/ \([^\(]*?(liquidation|executrix|formerly|trading)[^\)]*?\)/i, '')
    condensed_case_name.gsub!(/\s+/, ' ')
	"#{condensed_case_name}, #{neutral_citation}.pdf"
  end
end
