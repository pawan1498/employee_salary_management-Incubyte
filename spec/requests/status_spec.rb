require "rails_helper"

RSpec.describe "GET /", type: :request do
  it "returns a simple HTML status page" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include("text/html")
    expect(response.body).to include("ACME Salary Management API")
    expect(response.body).to include("/up")
    expect(response.body).not_to include("/api/insights")
  end
end
