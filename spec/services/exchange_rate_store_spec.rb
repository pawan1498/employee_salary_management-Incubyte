require "rails_helper"

RSpec.describe ExchangeRateStore do
  it "refreshes stale rates from Frankfurter" do
    stub_request(:get, frankfurter_url("USD"))
      .to_return(
        status: 200,
        body: {
          base: "USD",
          date: "2026-09-19",
          rates: { "INR" => 83.5, "GBP" => 0.79, "EUR" => 0.92, "CAD" => 1.35 }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = described_class.new("USD").refresh_if_stale!

    expect(result.fetch(:rates_as_of)).to eq(Date.new(2026, 9, 19))
    expect(result.fetch(:stale)).to eq(false)
    expect(result.fetch(:rates).fetch("INR")).to eq(BigDecimal("83.5"))
  end

  it "returns cached rates when they are still fresh" do
    ExchangeRate.create!(
      base_currency: "USD",
      quote_currency: "INR",
      rate: 83.5,
      fetched_at: 1.hour.ago
    )
    ExchangeRate.create!(
      base_currency: "USD",
      quote_currency: "USD",
      rate: 1.0,
      fetched_at: 1.hour.ago
    )

    result = described_class.new("USD").refresh_if_stale!

    expect(result.fetch(:stale)).to eq(false)
    expect(WebMock).not_to have_requested(:get, frankfurter_url("USD"))
  end

  context "when Frankfurter is unavailable but cached rates exist" do
    it "returns stale cached rates" do
      ExchangeRate.create!(
        base_currency: "USD",
        quote_currency: "INR",
        rate: 83.5,
        fetched_at: 2.days.ago
      )
      ExchangeRate.create!(
        base_currency: "USD",
        quote_currency: "USD",
        rate: 1.0,
        fetched_at: 2.days.ago
      )
      stub_request(:get, frankfurter_url("USD")).to_return(status: 503)

      result = described_class.new("USD").refresh_if_stale!

      expect(result.fetch(:stale)).to eq(true)
      expect(result.fetch(:rates).fetch("INR")).to eq(BigDecimal("83.5"))
    end
  end

  context "when Frankfurter is unavailable and no cache exists" do
    it "raises UnavailableError" do
      stub_request(:get, frankfurter_url("USD")).to_return(status: 503)

      expect do
        described_class.new("USD").refresh_if_stale!
      end.to raise_error(ExchangeRateFetcher::UnavailableError)
    end
  end
end
