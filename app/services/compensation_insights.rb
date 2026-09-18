class CompensationInsights
  TABLE = CurrentSalaryRecordsQuery::TABLE

  def self.call(employees)
    new(employees).as_json
  end

  def initialize(employees)
    @employees = employees
    @current_salaries = CurrentSalaryRecordsQuery.new(employees).relation
  end

  def as_json(*)
    {
      headcount: @employees.count,
      by_currency: currency_rows,
      by_country: country_rows,
      by_department: department_rows,
      distribution: distribution_rows
    }
  end

  private

  def currency_rows
    grouped_totals("#{TABLE}.currency").map do |row|
      money_row(
        currency: row.currency,
        headcount: row.employee_count,
        total: row.total_amount,
        average: row.average_amount
      )
    end
  end

  def country_rows
    grouped_totals("#{TABLE}.country", "#{TABLE}.currency").map do |row|
      money_row(
        country: row.country,
        currency: row.currency,
        headcount: row.employee_count,
        total: row.total_amount,
        average: row.average_amount
      )
    end
  end

  def department_rows
    grouped_totals("#{TABLE}.department", "#{TABLE}.currency").map do |row|
      money_row(
        department: row.department,
        currency: row.currency,
        headcount: row.employee_count,
        total: row.total_amount,
        average: row.average_amount
      )
    end
  end

  def distribution_rows
    @current_salaries
      .group("#{TABLE}.currency", Arel.sql(amount_bucket_sql))
      .order("#{TABLE}.currency", Arel.sql(amount_bucket_sql))
      .select(
        "#{TABLE}.currency AS currency",
        "#{amount_bucket_sql} AS bucket",
        "COUNT(*) AS employee_count"
      )
      .map do |row|
        { currency: row.currency, bucket: row.bucket, headcount: row.employee_count.to_i }
      end
  end

  def grouped_totals(*columns)
    @current_salaries
      .group(*columns)
      .order(*columns)
      .select(
        *columns,
        "COUNT(*) AS employee_count",
        "SUM(#{TABLE}.amount) AS total_amount",
        "AVG(#{TABLE}.amount) AS average_amount"
      )
  end

  def amount_bucket_sql
    <<~SQL.squish
      CASE
        WHEN #{TABLE}.amount < 50000 THEN '0-49999'
        WHEN #{TABLE}.amount < 100000 THEN '50000-99999'
        WHEN #{TABLE}.amount < 150000 THEN '100000-149999'
        ELSE '150000+'
      END
    SQL
  end

  def money_row(headcount:, total:, average:, **identity)
    identity.merge(
      headcount: headcount.to_i,
      total: format_money(total),
      average: format_money(average)
    )
  end

  def format_money(value)
    BigDecimal(value.to_s).round(2).to_s("F")
  end
end
