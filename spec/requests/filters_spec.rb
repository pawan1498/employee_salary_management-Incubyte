require "rails_helper"

RSpec.describe "GET /api/filters", type: :request do
  def json_body
    JSON.parse(response.body)
  end

  it "returns static country, department, and role options for search dropdowns" do
    get "/api/filters"

    expect(response).to have_http_status(:ok)
    data = json_body.fetch("data")
    expect(data.fetch("countries")).to eq(
      [
        "United States",
        "United Kingdom",
        "India",
        "Germany",
        "Canada"
      ]
    )
    expect(data.fetch("departments")).to eq(
      [
        "Engineering",
        "People",
        "Finance",
        "Sales",
        "Operations"
      ]
    )
    expect(data.fetch("roles")).to include("Software Engineer", "Recruiter")
  end
end
