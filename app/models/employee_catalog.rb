# Static country and department values for filters and seed data.
class EmployeeCatalog
  LOCATIONS = [
    { country: "United States", currency: "USD", min: 55_000, max: 175_000 },
    { country: "United Kingdom", currency: "GBP", min: 35_000, max: 120_000 },
    { country: "India", currency: "INR", min: 600_000, max: 2_500_000 },
    { country: "Germany", currency: "EUR", min: 40_000, max: 130_000 },
    { country: "Canada", currency: "CAD", min: 50_000, max: 160_000 }
  ].freeze

  DEPARTMENTS = {
    "Engineering" => [ "Software Engineer", "Backend Engineer", "Engineering Manager" ].freeze,
    "People" => [ "HR Generalist", "Recruiter" ].freeze,
    "Finance" => [ "Accountant", "Financial Analyst" ].freeze,
    "Sales" => [ "Account Executive", "Sales Manager" ].freeze,
    "Operations" => [ "Operations Specialist", "Office Manager" ].freeze
  }.freeze

  def self.countries
    LOCATIONS.map { |location| location.fetch(:country) }
  end

  def self.departments
    DEPARTMENTS.keys
  end

  def self.filter_options
    { countries: countries, departments: departments }
  end
end
