require "rails_helper"

RSpec.describe "GET /api/filters", type: :request do
  def json_body
    JSON.parse(response.body)
  end

  it "returns static country and department options for search dropdowns" do
    get "/api/filters"

    expect(response).to have_http_status(:ok)
    expect(json_body.fetch("data")).to eq(
      "countries" => [
        "United States",
        "United Kingdom",
        "India",
        "Germany",
        "Canada"
      ],
      "departments" => [
        "Engineering",
        "People",
        "Finance",
        "Sales",
        "Operations"
      ]
    )
  end
end
