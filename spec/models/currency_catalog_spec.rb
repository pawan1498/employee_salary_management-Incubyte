require "rails_helper"

RSpec.describe CurrencyCatalog do
  it "maps every seed country to a supported currency" do
    described_class::COUNTRY_CURRENCY.each_value do |currency|
      expect(described_class.supported?(currency)).to eq(true)
    end
  end

  it "includes all country salary currencies in the single currencies list" do
    country_currencies = described_class::COUNTRY_CURRENCY.values.uniq.sort
    expect(described_class.currencies).to include(*country_currencies)
  end

  it "excludes Frankfurter-unsupported currencies such as BGN" do
    expect(described_class.currencies).not_to include("BGN")
  end

  it "builds Frankfurter hub quotes from the currencies list" do
    expect(described_class.frankfurter_hub_quotes).to include("JPY", "INR")
    expect(described_class.frankfurter_hub_quotes).not_to include("USD")
  end

  it "validates supported membership" do
    expect(described_class.supported?("JPY")).to eq(true)
    expect(described_class.supported?("XYZ")).to eq(false)
    expect(described_class.supported?("BGN")).to eq(false)
  end

  it "looks up currency by country" do
    expect(described_class.currency_for("India")).to eq("INR")
    expect { described_class.currency_for("Unknown") }.to raise_error(KeyError)
  end
end
