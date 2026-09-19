require "rails_helper"

RSpec.describe ExchangeRateStore do
  it "refreshes stale USD hub rates from Frankfurter" do
    stub_request(:get, frankfurter_url)
      .to_return(
        status: 200,
        body: {
          base: "USD",
          date: "2026-09-19",
          rates: { "INR" => 83.5, "GBP" => 0.79, "EUR" => 0.92, "CAD" => 1.35, "JPY" => 149.25 }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = described_class.new("USD").refresh_if_stale!

    expect(result.fetch(:rates_as_of)).to eq(Date.new(2026, 9, 19))
    expect(result.fetch(:stale)).to eq(false)
    expect(result.fetch(:rates).fetch("INR")).to eq(BigDecimal("83.5"))
  end

  it "derives non-USD reporting rates from the USD hub cache" do
    seed_exchange_rates

    result = described_class.new("JPY").refresh_if_stale!

    expect(result.fetch(:base_currency)).to eq("JPY")
    expect(result.fetch(:rates).fetch("USD")).to eq(BigDecimal("1") / BigDecimal("149.25"))
  end

  it "returns cached hub rates when they are still fresh" do
    seed_exchange_rates(fetched_at: 1.hour.ago)

    result = described_class.new("USD").refresh_if_stale!

    expect(result.fetch(:stale)).to eq(false)
    expect(WebMock).not_to have_requested(:get, frankfurter_url)
  end

  context "when Frankfurter is unavailable but cached hub rates exist" do
    it "returns stale derived rates" do
      seed_exchange_rates(fetched_at: 2.days.ago)
      stub_request(:get, frankfurter_url).to_return(status: 503)

      result = described_class.new("USD").refresh_if_stale!

      expect(result.fetch(:stale)).to eq(true)
      expect(result.fetch(:rates).fetch("INR")).to eq(BigDecimal("83.5"))
    end
  end

  context "when Frankfurter is unavailable and no hub cache exists" do
    it "raises UnavailableError" do
      stub_request(:get, frankfurter_url).to_return(status: 503)

      expect do
        described_class.new("USD").refresh_if_stale!
      end.to raise_error(ExchangeRateFetcher::UnavailableError)
    end
  end
end
