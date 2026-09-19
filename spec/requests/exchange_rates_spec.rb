require "rails_helper"

RSpec.describe "GET /api/exchange_rates", type: :request do
  def json_body
    JSON.parse(response.body)
  end

  before do
    seed_exchange_rates
  end

  it "returns cached rates for the requested base currency" do
    get "/api/exchange_rates", params: { base_currency: "USD" }

    expect(response).to have_http_status(:ok)
    data = json_body.fetch("data")
    expect(data.fetch("base_currency")).to eq("USD")
    expect(data.fetch("rates_as_of")).to be_present
    expect(BigDecimal(data.fetch("rates").fetch("GBP"))).to eq(BigDecimal("0.79"))
  end

  context "when base_currency is not supported" do
    it "returns validation errors" do
      get "/api/exchange_rates", params: { base_currency: "XYZ" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.fetch("errors")).to include("Base currency is not supported")
    end
  end

  context "when exchange rates are unavailable" do
    it "returns a service unavailable error" do
      ExchangeRate.delete_all
      stub_request(:get, /api\.frankfurter\.dev/).to_return(status: 503)

      get "/api/exchange_rates"

      expect(response).to have_http_status(:service_unavailable)
      expect(json_body.fetch("errors")).to include("Exchange rates are temporarily unavailable")
    end
  end
end
