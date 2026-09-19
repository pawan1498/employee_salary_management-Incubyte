require "rails_helper"

RSpec.describe "Browser cross-origin access", type: :request do
  before do
    seed_exchange_rates
  end

  it "answers an OPTIONS preflight from the Vite origin" do
    process :options, "/api/insights", headers: {
      "Origin" => "http://localhost:5173",
      "Access-Control-Request-Method" => "GET"
    }

    expect(response).to have_http_status(:ok)
    expect(response.headers["Access-Control-Allow-Origin"]).to eq("http://localhost:5173")
  end

  it "includes an allow-origin header on GET from the Vite origin" do
    get "/api/insights", headers: { "Origin" => "http://localhost:5173" }

    expect(response).to have_http_status(:ok)
    expect(response.headers["Access-Control-Allow-Origin"]).to eq("http://localhost:5173")
  end

  it "includes an allow-origin header on GET /api/filters from the Vite origin" do
    get "/api/filters", headers: { "Origin" => "http://localhost:5173" }

    expect(response).to have_http_status(:ok)
    expect(response.headers["Access-Control-Allow-Origin"]).to eq("http://localhost:5173")
    expect(JSON.parse(response.body).fetch("data")).to include("reporting_currencies", "salary_currencies")
  end
end
