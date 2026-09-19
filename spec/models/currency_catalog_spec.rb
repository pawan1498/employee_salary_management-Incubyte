require "rails_helper"

RSpec.describe CurrencyCatalog do
  it "derives salary currencies from country mappings" do
    expected = described_class::COUNTRY_CURRENCY.values.uniq.sort
    expect(described_class.salary_currencies).to eq(expected)
  end

  it "includes all salary currencies in reporting currencies" do
    expect(described_class.reporting_currencies).to include(*described_class.salary_currencies)
  end

  it "validates reporting and salary membership" do
    expect(described_class.reporting?("JPY")).to eq(true)
    expect(described_class.reporting?("XYZ")).to eq(false)
    expect(described_class.salary?("INR")).to eq(true)
    expect(described_class.salary?("JPY")).to eq(false)
  end

  it "looks up currency by country" do
    expect(described_class.currency_for("India")).to eq("INR")
    expect { described_class.currency_for("Unknown") }.to raise_error(KeyError)
  end
end
