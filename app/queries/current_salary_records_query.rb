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
    subquery = Arel::Table.new(TABLE)

    SalaryRecord.from(ranked_current_relation, TABLE)
                .where(subquery[:salary_rank].eq(1))
                .select(
                  subquery[:id],
                  subquery[:employee_id],
                  subquery[:amount],
                  subquery[:currency],
                  subquery[:country],
                  subquery[:department]
                )
  end

  private

  def ranked_current_relation
    SalaryRecord.joins(:employee)
                .merge(@employees)
                .select(
                  "salary_records.id AS id",
                  "salary_records.employee_id AS employee_id",
                  "salary_records.amount AS amount",
                  "salary_records.currency AS currency",
                  "employees.country AS country",
                  "employees.department AS department",
                  Arel.sql(<<~SQL.squish)
                    ROW_NUMBER() OVER (
                      PARTITION BY salary_records.employee_id
                      ORDER BY salary_records.effective_date DESC, salary_records.id DESC
                    ) AS salary_rank
                  SQL
                )
  end
end
