require "rails_helper"

RSpec.describe "GET /api/employees", type: :request do
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
