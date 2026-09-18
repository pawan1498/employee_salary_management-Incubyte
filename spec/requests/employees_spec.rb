require "rails_helper"

module EmployeeRequestHelpers
  def json_body
    JSON.parse(response.body)
  end

  def create_employee(attrs = {})
    Employee.create!(
      {
        employee_number: "E-#{SecureRandom.hex(3)}",
        name: "Ada Lovelace",
        country: "United Kingdom",
        department: "Engineering",
        role: "Software Engineer"
      }.merge(attrs)
    )
  end
end

RSpec.describe "GET /api/employees", type: :request do
  include EmployeeRequestHelpers

  context "when no employees exist" do
    it "returns an empty list and a total of zero" do
      get "/api/employees"

      expect(response).to have_http_status(:ok)
      expect(json_body.fetch("data")).to eq([])
      expect(json_body.fetch("meta")).to include(
        "page" => 1,
        "per_page" => 25,
        "total" => 0
      )
    end
  end

  context "when employees exist" do
    it "includes employee number, name, country, department, and role" do
      create_employee(
        employee_number: "E-1001",
        name: "Grace Hopper",
        country: "United States",
        department: "Engineering",
        role: "Rear Admiral"
      )

      get "/api/employees"

      expect(response).to have_http_status(:ok)
      expect(json_body.fetch("data")).to contain_exactly(
        hash_including(
          "employee_number" => "E-1001",
          "name" => "Grace Hopper",
          "country" => "United States",
          "department" => "Engineering",
          "role" => "Rear Admiral"
        )
      )
    end

    it "includes the current salary for each employee" do
      employee = create_employee(employee_number: "E-1001", name: "Grace Hopper")
      employee.salary_records.create!(
        amount: 80_000,
        currency: "USD",
        effective_date: Date.new(2024, 1, 1)
      )
      employee.salary_records.create!(
        amount: 95_000,
        currency: "USD",
        effective_date: Date.new(2026, 1, 15)
      )

      get "/api/employees"

      expect(response).to have_http_status(:ok)
      current = json_body.fetch("data").first.fetch("current_salary")
      expect(BigDecimal(current.fetch("amount").to_s)).to eq(95_000)
      expect(current).to include(
        "currency" => "USD",
        "effective_date" => "2026-01-15"
      )
    end

    it "returns only the requested page and the full total" do
      create_employee(name: "Asha", employee_number: "E-1")
      create_employee(name: "Bina", employee_number: "E-2")
      create_employee(name: "Chitra", employee_number: "E-3")

      get "/api/employees", params: { page: 1, per_page: 2 }

      expect(response).to have_http_status(:ok)
      expect(json_body.fetch("data").size).to eq(2)
      expect(json_body.fetch("meta")).to include(
        "page" => 1,
        "per_page" => 2,
        "total" => 3
      )
    end
  end

  context "when searching by name" do
    it "returns only employees whose name matches the query" do
      create_employee(name: "Grace Hopper", employee_number: "E-1001")
      create_employee(name: "Alan Turing", employee_number: "E-1002")

      get "/api/employees", params: { q: "Grace" }

      expect(response).to have_http_status(:ok)
      expect(json_body.fetch("data")).to contain_exactly(
        hash_including("name" => "Grace Hopper", "employee_number" => "E-1001")
      )
      expect(json_body.fetch("meta")).to include("total" => 1)
    end
  end

  context "when searching by employee number" do
    it "returns only the employee with that number" do
      create_employee(name: "Grace Hopper", employee_number: "E-1001")
      create_employee(name: "Alan Turing", employee_number: "E-1002")

      get "/api/employees", params: { q: "E-1002" }

      expect(response).to have_http_status(:ok)
      expect(json_body.fetch("data")).to contain_exactly(
        hash_including("name" => "Alan Turing", "employee_number" => "E-1002")
      )
    end
  end

  context "when filtering by country" do
    it "returns only employees in that country" do
      create_employee(name: "Grace Hopper", country: "United States", employee_number: "E-1")
      create_employee(name: "Ada Lovelace", country: "United Kingdom", employee_number: "E-2")

      get "/api/employees", params: { country: "United Kingdom" }

      expect(response).to have_http_status(:ok)
      expect(json_body.fetch("data")).to contain_exactly(
        hash_including("name" => "Ada Lovelace", "country" => "United Kingdom")
      )
      expect(json_body.fetch("meta")).to include("total" => 1)
    end
  end

  context "when filtering by department" do
    it "returns only employees in that department" do
      create_employee(name: "Grace Hopper", department: "Engineering", employee_number: "E-1")
      create_employee(name: "Mary HR", department: "People", employee_number: "E-2")

      get "/api/employees", params: { department: "People" }

      expect(response).to have_http_status(:ok)
      expect(json_body.fetch("data")).to contain_exactly(
        hash_including("name" => "Mary HR", "department" => "People")
      )
    end
  end

  context "when searching by role" do
    it "returns only employees whose role matches the query" do
      create_employee(name: "Grace Hopper", role: "Software Engineer", employee_number: "E-1")
      create_employee(name: "Mary HR", role: "Recruiter", employee_number: "E-2")

      get "/api/employees", params: { q: "Recruiter" }

      expect(response).to have_http_status(:ok)
      expect(json_body.fetch("data")).to contain_exactly(
        hash_including("name" => "Mary HR", "role" => "Recruiter")
      )
    end
  end

  context "when filtering by role" do
    it "returns only employees with that role" do
      create_employee(name: "Grace Hopper", role: "Software Engineer", employee_number: "E-1")
      create_employee(name: "Alan Turing", role: "Backend Engineer", employee_number: "E-2")

      get "/api/employees", params: { role: "Backend Engineer" }

      expect(response).to have_http_status(:ok)
      expect(json_body.fetch("data")).to contain_exactly(
        hash_including("name" => "Alan Turing", "role" => "Backend Engineer")
      )
    end
  end

  context "when combining search and country" do
    it "returns employees that match both" do
      create_employee(name: "Ana India", country: "India", employee_number: "E-1")
      create_employee(name: "Ana US", country: "United States", employee_number: "E-2")
      create_employee(name: "Bina India", country: "India", employee_number: "E-3")

      get "/api/employees", params: { q: "Ana", country: "India" }

      expect(response).to have_http_status(:ok)
      expect(json_body.fetch("data")).to contain_exactly(
        hash_including("name" => "Ana India", "country" => "India")
      )
    end
  end
end

RSpec.describe "GET /api/employees/:id", type: :request do
  include EmployeeRequestHelpers

  context "when the employee exists" do
    it "returns that employee's identity fields" do
      employee = create_employee(
        employee_number: "E-1001",
        name: "Grace Hopper",
        country: "United States",
        department: "Engineering",
        role: "Rear Admiral"
      )

      get "/api/employees/#{employee.id}"

      expect(response).to have_http_status(:ok)
      expect(json_body.fetch("data")).to include(
        "id" => employee.id,
        "employee_number" => "E-1001",
        "name" => "Grace Hopper",
        "country" => "United States",
        "department" => "Engineering",
        "role" => "Rear Admiral"
      )
    end

    it "returns the current salary and history newest first" do
      employee = create_employee(employee_number: "E-1001", name: "Grace Hopper")
      employee.salary_records.create!(
        amount: 80_000,
        currency: "USD",
        effective_date: Date.new(2024, 1, 1)
      )
      employee.salary_records.create!(
        amount: 95_000,
        currency: "USD",
        effective_date: Date.new(2026, 1, 15)
      )

      get "/api/employees/#{employee.id}"

      data = json_body.fetch("data")
      current = data.fetch("current_salary")
      expect(BigDecimal(current.fetch("amount").to_s)).to eq(95_000)
      expect(current).to include("currency" => "USD", "effective_date" => "2026-01-15")

      history = data.fetch("salary_history")
      expect(history.map { |row| row.fetch("effective_date") }).to eq(%w[2026-01-15 2024-01-01])
    end

    it "uses the later record when two salaries share an effective date" do
      employee = create_employee(employee_number: "E-1001")
      employee.salary_records.create!(
        amount: 50_000,
        currency: "USD",
        effective_date: Date.new(2026, 1, 15)
      )
      employee.salary_records.create!(
        amount: 60_000,
        currency: "USD",
        effective_date: Date.new(2026, 1, 15)
      )

      get "/api/employees/#{employee.id}"

      current = json_body.fetch("data").fetch("current_salary")
      expect(BigDecimal(current.fetch("amount").to_s)).to eq(60_000)
    end
  end

  context "when the employee has no salary records" do
    it "returns a null current salary and an empty history" do
      employee = create_employee

      get "/api/employees/#{employee.id}"

      expect(json_body.fetch("data")).to include(
        "current_salary" => nil,
        "salary_history" => []
      )
    end
  end

  context "when the employee does not exist" do
    it "returns not found with an errors list" do
      get "/api/employees/0"

      expect(response).to have_http_status(:not_found)
      expect(json_body.fetch("errors")).to be_present
    end
  end
end
