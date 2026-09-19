require "rails_helper"

RSpec.describe EmployeeCatalog do
  it "assigns currency from CurrencyCatalog for every location" do
    described_class::LOCATIONS.each do |location|
      country = location.fetch(:country)
      expect(location.fetch(:currency)).to eq(CurrencyCatalog.currency_for(country))
    end
  end

  it "covers every country in CurrencyCatalog" do
    expect(described_class.countries.sort).to eq(CurrencyCatalog.countries)
  end
end
