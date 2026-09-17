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
      expect(employee.salary_records.count).to eq(1)
    end

    context "when amount is invalid" do
      it "does not create a record" do
        post "/api/employees/#{employee.id}/salary_records",
             params: { salary_record: { amount: 0, currency: "INR", effective_date: "2026-01-15" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(employee.salary_records.count).to eq(0)
      end
    end

    context "when a salary already exists" do
      it "keeps the previous record" do
        previous = employee.salary_records.create!(
          amount: 80_000,
          currency: "INR",
          effective_date: Date.new(2024, 1, 1)
        )

        post "/api/employees/#{employee.id}/salary_records", params: valid_params

        expect(response).to have_http_status(:created)
        expect(employee.salary_records.count).to eq(2)
        expect(previous.reload.amount).to eq(80_000)
      end
    end

    context "when the employee does not exist" do
      it "returns not found" do
        post "/api/employees/0/salary_records", params: valid_params

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
