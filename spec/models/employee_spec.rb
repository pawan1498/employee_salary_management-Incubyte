require "rails_helper"

RSpec.describe Employee, type: :model do
  def create_employee
    Employee.create!(
      employee_number: "E-#{SecureRandom.hex(3)}",
      name: "Ada Lovelace",
      country: "United Kingdom",
      department: "Engineering",
      role: "Software Engineer"
    )
  end

  describe "#current_salary_record" do
    it "returns the salary with the latest effective date" do
      employee = create_employee
      employee.salary_records.create!(
        amount: 80_000,
        currency: "GBP",
        effective_date: Date.new(2024, 1, 1)
      )
      current = employee.salary_records.create!(
        amount: 90_000,
        currency: "GBP",
        effective_date: Date.new(2026, 1, 1)
      )

      expect(employee.current_salary_record).to eq(current)
    end

    it "returns the later record when effective dates match" do
      employee = create_employee
      employee.salary_records.create!(
        amount: 50_000,
        currency: "GBP",
        effective_date: Date.new(2026, 1, 15)
      )
      later = employee.salary_records.create!(
        amount: 60_000,
        currency: "GBP",
        effective_date: Date.new(2026, 1, 15)
      )

      expect(employee.current_salary_record).to eq(later)
    end
  end
end
