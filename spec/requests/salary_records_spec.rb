require "rails_helper"

RSpec.describe "Salary records API", type: :request do
  let(:employee) do
    Employee.create!(
      employee_number: "E-1001",
      name: "Pawan Sharma",
      country: "India",
      department: "Engineering",
      role: "Backend Engineer"
    )
  end

  let(:valid_params) do
    {
      salary_record: {
        amount: 100_000,
        currency: "INR",
        effective_date: "2026-01-15"
      }
    }
  end

  describe "POST /api/employees/:employee_id/salary_records" do
    it "creates a salary record" do
      post "/api/employees/#{employee.id}/salary_records", params: valid_params

      expect(response).to have_http_status(:created)
    end
  end
end
