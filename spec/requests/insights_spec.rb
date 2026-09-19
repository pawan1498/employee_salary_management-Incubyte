require "rails_helper"

RSpec.describe "GET /api/insights", type: :request do
  def json_body
    JSON.parse(response.body)
  end

  def create_employee_with_salary(attrs = {}, salary = {})
    employee = Employee.create!(
      {
        employee_number: "E-#{SecureRandom.hex(3)}",
        name: "Ada Lovelace",
        country: "United Kingdom",
        department: "Engineering",
        role: "Software Engineer"
      }.merge(attrs)
    )
    employee.salary_records.create!(
      {
        amount: 80_000,
        currency: "GBP",
        effective_date: Date.new(2026, 1, 1)
      }.merge(salary)
    )
    employee
  end

  before do
    seed_exchange_rates
  end

  context "when no employees exist" do
    it "returns a headcount of zero and empty breakdowns" do
      get "/api/insights"

      expect(response).to have_http_status(:ok)
      data = json_body.fetch("data")
      expect(data.fetch("base_currency")).to eq("USD")
      expect(data.fetch("headcount")).to eq(0)
      expect(data.fetch("total")).to eq("0.00")
      expect(data.fetch("average")).to eq("0.00")
      expect(data.fetch("by_country")).to eq([])
      expect(data.fetch("by_department")).to eq([])
      expect(data.fetch("distribution")).to eq([])
    end
  end

  context "when employees are paid in different currencies" do
    it "returns org-wide totals converted to the HR default currency" do
      create_employee_with_salary(
        { country: "United States", department: "Engineering" },
        { amount: 100_000, currency: "USD" }
      )
      create_employee_with_salary(
        { country: "United States", department: "Engineering" },
        { amount: 50_000, currency: "USD" }
      )
      create_employee_with_salary(
        { country: "India", department: "Engineering" },
        { amount: 83_500, currency: "INR" }
      )

      get "/api/insights"

      data = json_body.fetch("data")
      expect(data.fetch("base_currency")).to eq("USD")
      expect(data.fetch("headcount")).to eq(3)
      expect(BigDecimal(data.fetch("total"))).to eq(151_000)
      expect(BigDecimal(data.fetch("average"))).to eq(50_333.33)
    end
  end

  context "when grouping by country and department" do
    it "returns converted totals without a currency field on each row" do
      create_employee_with_salary(
        { country: "India", department: "People" },
        { amount: 83_500, currency: "INR" }
      )
      create_employee_with_salary(
        { country: "India", department: "Engineering" },
        { amount: 167_000, currency: "INR" }
      )

      get "/api/insights"

      data = json_body.fetch("data")
      expect(data.fetch("by_country")).to contain_exactly(
        hash_including("country" => "India", "headcount" => 2, "total" => "3000.00")
      )
      expect(data.fetch("by_department")).to contain_exactly(
        hash_including("department" => "People", "headcount" => 1, "total" => "1000.00"),
        hash_including("department" => "Engineering", "headcount" => 1, "total" => "2000.00")
      )
      expect(data.fetch("by_country").first).not_to have_key("currency")
    end
  end

  context "when salaries fall into different amounts" do
    it "counts converted salaries into buckets in the default currency" do
      create_employee_with_salary({}, { amount: 40_000, currency: "USD" })
      create_employee_with_salary({}, { amount: 60_000, currency: "USD" })
      create_employee_with_salary({}, { amount: 120_000, currency: "USD" })
      create_employee_with_salary({}, { amount: 200_000, currency: "USD" })

      get "/api/insights"

      expect(json_body.fetch("data").fetch("distribution")).to contain_exactly(
        hash_including("bucket" => "0-49999", "headcount" => 1),
        hash_including("bucket" => "50000-99999", "headcount" => 1),
        hash_including("bucket" => "100000-149999", "headcount" => 1),
        hash_including("bucket" => "150000+", "headcount" => 1)
      )
    end
  end

  context "when an employee has salary history" do
    it "aggregates only the current salary" do
      employee = create_employee_with_salary({}, { amount: 50_000, currency: "USD", effective_date: Date.new(2024, 1, 1) })
      employee.salary_records.create!(
        amount: 80_000,
        currency: "USD",
        effective_date: Date.new(2026, 1, 1)
      )

      get "/api/insights"

      data = json_body.fetch("data")
      expect(data.fetch("headcount")).to eq(1)
      expect(BigDecimal(data.fetch("total"))).to eq(80_000)
    end
  end

  context "when filtering by country" do
    it "returns insights for employees in that country only" do
      create_employee_with_salary(
        { country: "India", department: "Engineering" },
        { amount: 83_500, currency: "INR" }
      )
      create_employee_with_salary(
        { country: "United States", department: "Engineering" },
        { amount: 100_000, currency: "USD" }
      )

      get "/api/insights", params: { country: "India" }

      data = json_body.fetch("data")
      expect(data.fetch("headcount")).to eq(1)
      expect(BigDecimal(data.fetch("total"))).to eq(1_000)
    end
  end

  context "when base_currency is JPY" do
    before do
      ExchangeRate.delete_all
      seed_exchange_rates(
        base_currency: "JPY",
        rates: {
          "JPY" => BigDecimal("1.0"),
          "USD" => BigDecimal("0.0067"),
          "GBP" => BigDecimal("0.0053"),
          "EUR" => BigDecimal("0.0062"),
          "INR" => BigDecimal("0.56"),
          "CAD" => BigDecimal("0.0091")
        }
      )
    end

    it "returns org-wide totals converted to JPY" do
      create_employee_with_salary(
        { country: "United States", department: "Engineering" },
        { amount: 100_000, currency: "USD" }
      )

      get "/api/insights", params: { base_currency: "JPY" }

      data = json_body.fetch("data")
      expect(data.fetch("base_currency")).to eq("JPY")
      expected_total = (BigDecimal("100000") / BigDecimal("0.0067")).round(2)
      expect(BigDecimal(data.fetch("total"))).to eq(expected_total)
    end
  end

  context "when base_currency is not supported" do
    it "returns validation errors" do
      get "/api/insights", params: { base_currency: "XYZ" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.fetch("errors")).to include("Base currency is not supported")
    end
  end

  context "when exchange rates are unavailable" do
    it "returns a service unavailable error" do
      ExchangeRate.delete_all
      stub_request(:get, /api\.frankfurter\.dev/).to_return(status: 503)

      get "/api/insights"

      expect(response).to have_http_status(:service_unavailable)
      expect(json_body.fetch("errors")).to include("Exchange rates are temporarily unavailable")
    end
  end
end
