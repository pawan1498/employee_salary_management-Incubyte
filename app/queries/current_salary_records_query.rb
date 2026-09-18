# Current pay for a set of employees.
#
# Same rule as Employee#current_salary_record:
# latest effective_date, and if two rows share that date, the later id.
class CurrentSalaryRecordsQuery
  def initialize(employees)
    @employees = employees
  end

  def relation
    SalaryRecord.joins(:employee).merge(@employees).where(id: current_salary_ids)
  end

  private

  def current_salary_ids
    SalaryRecord
      .where("(employee_id, effective_date) IN (#{latest_effective_dates.to_sql})")
      .group(:employee_id)
      .select("MAX(id)")
  end

  def latest_effective_dates
    SalaryRecord.group(:employee_id).select(:employee_id, "MAX(effective_date)")
  end
end
