require "rails_helper"

RSpec.describe EmployeeSeeder do
  it "creates the requested number of employees each with a current salary" do
    EmployeeSeeder.new(count: 5, random: Random.new(1)).call

    expect(Employee.count).to eq(5)
    expect(Employee.joins(:salary_records).distinct.count).to eq(5)
  end

  it "creates some earlier salary records so history can be demonstrated" do
    EmployeeSeeder.new(count: 12, random: Random.new(1)).call

    employees_with_history = Employee.joins(:salary_records)
                                     .group("employees.id")
                                     .having("COUNT(salary_records.id) > 1")
                                     .count

    expect(employees_with_history.size).to be > 0
  end

  it "does not create extra employees when the directory is already full" do
    EmployeeSeeder.new(count: 3, random: Random.new(1)).call
    EmployeeSeeder.new(count: 3, random: Random.new(1)).call

    expect(Employee.count).to eq(3)
  end

  it "uses one currency per country" do
    EmployeeSeeder.new(count: 8, random: Random.new(1)).call

    Employee.includes(:salary_records).find_each do |employee|
      currencies = employee.salary_records.map(&:currency).uniq
      expect(currencies.size).to eq(1)
    end
  end

  it "creates varied employee names" do
    EmployeeSeeder.new(count: 100, random: Random.new(42)).call

    names = Employee.pluck(:name)
    expect(names.uniq.size).to be >= 80
  end

  it "spreads employees across countries and departments" do
    EmployeeSeeder.new(count: 200, random: Random.new(42)).call

    expect(Employee.distinct.pluck(:country).size).to be >= 4
    expect(Employee.distinct.pluck(:department).size).to be >= 4
  end
end
