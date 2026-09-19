# Picks each employee's current salary row in SQL (for insights over ~10,000 people).
#
# Business rule — same as Employee#current_salary_record:
#   • newest effective_date wins
#   • same date → row with the higher id wins
#
# How it works:
#   1. rank every salary row per employee (1 = current, 2+ = history)
#   2. keep rows where rank = 1
#
# Employee country/department are included so insights can GROUP BY them without
# extra joins on this derived table (the SQL alias is `current_salary`).
class CurrentSalaryRecordsQuery
  ALIAS = "current_salary"

  def initialize(employees)
    @employees = employees
  end

  def relation
    current = Arel::Table.new(ALIAS)

    SalaryRecord
      .from(ranked_salary_rows, ALIAS)
      .where(current[:salary_rank].eq(1))
      .select(
        current[:id],
        current[:employee_id],
        current[:amount],
        current[:currency],
        current[:country],
        current[:department]
      )
  end

  private

  def ranked_salary_rows
    SalaryRecord
      .joins(:employee)
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
