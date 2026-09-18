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

  context "when no employees exist" do
    it "returns a headcount of zero and empty breakdowns" do
      get "/api/insights"

      expect(response).to have_http_status(:ok)
      data = json_body.fetch("data")
      expect(data.fetch("headcount")).to eq(0)
      expect(data.fetch("by_currency")).to eq([])
      expect(data.fetch("by_country")).to eq([])
      expect(data.fetch("by_department")).to eq([])
      expect(data.fetch("distribution")).to eq([])
    end
  end

  context "when employees are paid in different currencies" do
    it "reports totals and averages per currency without mixing them" do
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
        { amount: 90_000, currency: "INR" }
      )

      get "/api/insights"

      by_currency = json_body.fetch("data").fetch("by_currency")
      usd = by_currency.detect { |row| row.fetch("currency") == "USD" }
      inr = by_currency.detect { |row| row.fetch("currency") == "INR" }

      expect(json_body.fetch("data").fetch("headcount")).to eq(3)
      expect(usd.fetch("headcount")).to eq(2)
      expect(BigDecimal(usd.fetch("total").to_s)).to eq(150_000)
      expect(BigDecimal(usd.fetch("average").to_s)).to eq(75_000)
      expect(inr.fetch("headcount")).to eq(1)
      expect(BigDecimal(inr.fetch("total").to_s)).to eq(90_000)
    end
  end

  context "when grouping by country and department" do
    it "includes currency on each breakdown row" do
      create_employee_with_salary(
        { country: "India", department: "People" },
        { amount: 70_000, currency: "INR" }
      )
      create_employee_with_salary(
        { country: "India", department: "Engineering" },
        { amount: 90_000, currency: "INR" }
      )

      get "/api/insights"

      data = json_body.fetch("data")
      expect(data.fetch("by_country")).to contain_exactly(
        hash_including("country" => "India", "currency" => "INR", "headcount" => 2)
      )
      expect(data.fetch("by_department")).to contain_exactly(
        hash_including("department" => "People", "currency" => "INR", "headcount" => 1),
        hash_including("department" => "Engineering", "currency" => "INR", "headcount" => 1)
      )
    end
  end

  context "when salaries fall into different amounts" do
    it "counts current salaries into buckets per currency" do
      create_employee_with_salary({}, { amount: 40_000, currency: "USD" })
      create_employee_with_salary({}, { amount: 60_000, currency: "USD" })
      create_employee_with_salary({}, { amount: 120_000, currency: "USD" })
      create_employee_with_salary({}, { amount: 200_000, currency: "USD" })

      get "/api/insights"

      expect(json_body.fetch("data").fetch("distribution")).to contain_exactly(
        hash_including("currency" => "USD", "bucket" => "0-49999", "headcount" => 1),
        hash_including("currency" => "USD", "bucket" => "50000-99999", "headcount" => 1),
        hash_including("currency" => "USD", "bucket" => "100000-149999", "headcount" => 1),
        hash_including("currency" => "USD", "bucket" => "150000+", "headcount" => 1)
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

      usd = json_body.fetch("data").fetch("by_currency").detect { |row| row.fetch("currency") == "USD" }
      expect(usd.fetch("headcount")).to eq(1)
      expect(BigDecimal(usd.fetch("total").to_s)).to eq(80_000)
    end
  end

  context "when filtering by country" do
    it "returns insights for employees in that country only" do
      create_employee_with_salary(
        { country: "India", department: "Engineering" },
        { amount: 90_000, currency: "INR" }
      )
      create_employee_with_salary(
        { country: "United States", department: "Engineering" },
        { amount: 100_000, currency: "USD" }
      )

      get "/api/insights", params: { country: "India" }

      data = json_body.fetch("data")
      expect(data.fetch("headcount")).to eq(1)
      expect(data.fetch("by_currency")).to contain_exactly(
        hash_including("currency" => "INR", "headcount" => 1)
      )
    end
  end
end
