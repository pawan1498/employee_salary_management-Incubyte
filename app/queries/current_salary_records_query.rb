# Current pay for a set of employees.
#
# Same rule as Employee#current_salary_record:
# latest effective_date, and if two rows share that date, the later id.
class CurrentSalaryRecordsQuery
  TABLE = "current_salary_records"

  def initialize(employees)
    @employees = employees
  end

  def relation
    SalaryRecord.from("(#{ranked_current_sql}) AS #{TABLE}")
                  .where("#{TABLE}.salary_rank = 1")
                  .select(
                    "#{TABLE}.id",
                    "#{TABLE}.employee_id",
                    "#{TABLE}.amount",
                    "#{TABLE}.currency",
                    "#{TABLE}.country",
                    "#{TABLE}.department"
                  )
  end

  private

  def ranked_current_sql
    SalaryRecord.joins(:employee)
                .merge(@employees)
                .select(
                  "salary_records.id AS id",
                  "salary_records.employee_id AS employee_id",
                  "salary_records.amount AS amount",
                  "salary_records.currency AS currency",
                  "employees.country AS country",
                  "employees.department AS department",
                  <<~SQL.squish
                    ROW_NUMBER() OVER (
                      PARTITION BY salary_records.employee_id
                      ORDER BY salary_records.effective_date DESC, salary_records.id DESC
                    ) AS salary_rank
                  SQL
                ).to_sql
  end
end
