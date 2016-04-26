class Judgment < Struct.new(:case_name, :neutral_citation, :decision_date, :catchwords, :url)
  attr_accessor :case_name, :neutral_citation, :decision_date, :catchwords, :url

  def initialize(args)
    super(*args.values_at(:case_name, :neutral_citation, :decision_date, :catchwords, :url))
  end

  def generate_filename
    "#{@case_name.gsub(/[\\\/:\*\?"<>|]/, '_')}, #{@neutral_citation}.pdf"
  end
end
