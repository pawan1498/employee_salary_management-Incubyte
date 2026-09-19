require "rails_helper"

RSpec.describe ExchangeRateFetcher do
  it "fetches USD hub rates from Frankfurter and stores them in the cache" do
    stub_request(:get, frankfurter_url)
      .to_return(
        status: 200,
        body: {
          base: "USD",
          date: "2026-09-19",
          rates: {
            "GBP" => 0.79,
            "EUR" => 0.92,
            "INR" => 83.5,
            "CAD" => 1.35,
            "JPY" => 149.25
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = described_class.new.call

    expect(result.fetch(:rates_as_of)).to eq(Date.new(2026, 9, 19))
    expect(result.fetch(:stale)).to eq(false)
    expect(ExchangeRate.find_by!(base_currency: "USD", quote_currency: "INR").rate).to eq(BigDecimal("83.5"))
    expect(ExchangeRate.find_by!(base_currency: "USD", quote_currency: "USD").rate).to eq(BigDecimal("1.0"))
    expect(ExchangeRate.find_by!(base_currency: "USD", quote_currency: "JPY").rate).to eq(BigDecimal("149.25"))
  end

  context "when Frankfurter is unavailable" do
    it "raises UnavailableError" do
      stub_request(:get, frankfurter_url).to_return(status: 503)

      expect do
        described_class.new.call
      end.to raise_error(ExchangeRateFetcher::UnavailableError)
    end
  end
end
