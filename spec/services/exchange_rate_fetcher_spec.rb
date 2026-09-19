require "rails_helper"

RSpec.describe ExchangeRateFetcher do
  it "fetches rates from Frankfurter and stores them in the cache" do
    stub_request(:get, frankfurter_url("USD"))
      .to_return(
        status: 200,
        body: {
          base: "USD",
          date: "2026-09-19",
          rates: {
            "GBP" => 0.79,
            "EUR" => 0.92,
            "INR" => 83.5,
            "CAD" => 1.35
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = described_class.new("USD").call

    expect(result.fetch(:rates_as_of)).to eq(Date.new(2026, 9, 19))
    expect(result.fetch(:stale)).to eq(false)
    expect(ExchangeRate.find_by!(base_currency: "USD", quote_currency: "INR").rate).to eq(BigDecimal("83.5"))
    expect(ExchangeRate.find_by!(base_currency: "USD", quote_currency: "USD").rate).to eq(BigDecimal("1.0"))
  end

  it "fetches salary-currency rates when the reporting currency is JPY" do
    stub_request(:get, frankfurter_url("JPY"))
      .to_return(
        status: 200,
        body: {
          base: "JPY",
          date: "2026-09-19",
          rates: {
            "USD" => 0.0067,
            "GBP" => 0.0053,
            "EUR" => 0.0062,
            "INR" => 0.56,
            "CAD" => 0.0091
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    described_class.new("JPY").call

    expect(ExchangeRate.find_by!(base_currency: "JPY", quote_currency: "USD").rate).to eq(BigDecimal("0.0067"))
  end

  context "when Frankfurter is unavailable" do
    it "raises UnavailableError" do
      stub_request(:get, frankfurter_url("USD")).to_return(status: 503)

      expect do
        described_class.new("USD").call
      end.to raise_error(ExchangeRateFetcher::UnavailableError)
    end
  end
end
