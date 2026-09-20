# Reference data (not an ActiveRecord model). Static country and department values for filters and seed data.
# Country → currency always comes from CurrencyCatalog (never duplicated here).
class EmployeeCatalog
  SALARY_RANGES = [
    { country: "United States", min: 55_000, max: 175_000 },
    { country: "United Kingdom", min: 35_000, max: 120_000 },
    { country: "India", min: 600_000, max: 2_500_000 },
    { country: "Germany", min: 40_000, max: 130_000 },
    { country: "Canada", min: 50_000, max: 160_000 }
  ].freeze

  LOCATIONS = SALARY_RANGES.map do |location|
    country = location.fetch(:country)
    {
      country: country,
      currency: CurrencyCatalog.currency_for(country),
      min: location.fetch(:min),
      max: location.fetch(:max)
    }
  end.freeze

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

  def self.roles
    DEPARTMENTS.values.flatten.uniq.sort
  end

  def self.filter_options
    {
      countries: countries,
      departments: departments,
      roles: roles,
      currencies: CurrencyCatalog.currencies,
      default_base_currency: CurrencyCatalog.default
    }
  end
end
