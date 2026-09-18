require "rails_helper"

RSpec.describe CurrentSalaryRecordsQuery do
  def create_employee
    Employee.create!(
      employee_number: "E-#{SecureRandom.hex(3)}",
      name: "Ada Lovelace",
      country: "United Kingdom",
      department: "Engineering",
      role: "Software Engineer"
    )
  end

  it "returns the salary with the latest effective date for each employee" do
    employee = create_employee
    employee.salary_records.create!(
      amount: 50_000,
      currency: "GBP",
      effective_date: Date.new(2024, 1, 1)
    )
    current = employee.salary_records.create!(
      amount: 80_000,
      currency: "GBP",
      effective_date: Date.new(2026, 1, 1)
    )

    records = CurrentSalaryRecordsQuery.new(Employee.where(id: employee.id)).relation

    expect(records).to contain_exactly(current)
  end

  it "returns the later record when two salaries share an effective date" do
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

    records = CurrentSalaryRecordsQuery.new(Employee.where(id: employee.id)).relation

    expect(records).to contain_exactly(later)
  end

  it "only includes salaries for the given employees" do
    included = create_employee
    excluded = create_employee
    kept = included.salary_records.create!(
      amount: 70_000,
      currency: "GBP",
      effective_date: Date.new(2026, 1, 1)
    )
    excluded.salary_records.create!(
      amount: 90_000,
      currency: "GBP",
      effective_date: Date.new(2026, 1, 1)
    )

    records = CurrentSalaryRecordsQuery.new(Employee.where(id: included.id)).relation

    expect(records).to contain_exactly(kept)
  end
end
