class Employee < ApplicationRecord
  has_many :salary_records, dependent: :restrict_with_exception

  validates :employee_number, :name, :country, :department, :role, presence: true
  validates :employee_number, uniqueness: true

  def self.search(query)
    return all if query.blank?

    pattern = "%#{sanitize_sql_like(query.strip)}%"
    where(
      "name LIKE :pattern OR employee_number LIKE :pattern OR role LIKE :pattern",
      pattern: pattern
    )
  end

  def self.in_country(country)
    return all if country.blank?

    where(country: country)
  end

  def self.in_department(department)
    return all if department.blank?

    where(department: department)
  end

  def self.in_role(role)
    return all if role.blank?

    where(role: role)
  end

  def current_salary_record
    if salary_records.loaded?
      salary_records.max_by { |record| [ record.effective_date, record.id ] }
    else
      salary_records.newest_first.first
    end
  end

  def salary_history
    if salary_records.loaded?
      salary_records.sort_by { |record| [ record.effective_date, record.id ] }.reverse
    else
      salary_records.newest_first.to_a
    end
  end
end
