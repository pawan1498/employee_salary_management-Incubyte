class Employee < ApplicationRecord
  validates :employee_number, :name, :country, :department, :role, presence: true
  validates :employee_number, uniqueness: true

  def self.search(query)
    return all if query.blank?

    pattern = "%#{sanitize_sql_like(query.strip)}%"
    where("name LIKE :pattern OR employee_number LIKE :pattern", pattern: pattern)
  end

  def self.in_country(country)
    return all if country.blank?

    where(country: country)
  end

  def self.in_department(department)
    return all if department.blank?

    where(department: department)
  end
end
