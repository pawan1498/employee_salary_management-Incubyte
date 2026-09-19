class CompensationInsights
  # Column prefix for rows returned by CurrentSalaryRecordsQuery (a SQL subquery alias).
  SALARY = CurrentSalaryRecordsQuery::ALIAS
  CONVERTED_AMOUNT_SQL = "CAST(#{SALARY}.amount AS REAL) / exchange_rates.rate".freeze
  SUM_CONVERTED_SQL = "SUM(#{CONVERTED_AMOUNT_SQL})".freeze
  AVG_CONVERTED_SQL = "AVG(#{CONVERTED_AMOUNT_SQL})".freeze
  AMOUNT_BUCKET_SQL = <<~SQL.squish.freeze
    CASE
      WHEN #{CONVERTED_AMOUNT_SQL} < 50000 THEN '0-49999'
      WHEN #{CONVERTED_AMOUNT_SQL} < 100000 THEN '50000-99999'
      WHEN #{CONVERTED_AMOUNT_SQL} < 150000 THEN '100000-149999'
      ELSE '150000+'
    END
  SQL
  EXCHANGE_RATE_JOIN_SQL = <<~SQL.squish.freeze
    INNER JOIN exchange_rates
      ON exchange_rates.quote_currency = #{SALARY}.currency
     AND exchange_rates.base_currency = ?
  SQL

  def self.call(employees, base_currency:, rates_as_of:)
    new(employees, base_currency:, rates_as_of:).as_json
  end

  def initialize(employees, base_currency:, rates_as_of:)
    @employees = employees
    @base_currency = base_currency.to_s.upcase
    @rates_as_of = rates_as_of
    @current_salaries = CurrentSalaryRecordsQuery.new(employees).relation
  end

  def as_json(*)
    total_amount, average_amount, median_amount = org_stats

    {
      base_currency: @base_currency,
      rates_as_of: @rates_as_of.iso8601,
      headcount: @employees.count,
      total: format_money(total_amount),
      average: format_money(average_amount),
      median: format_money(median_amount),
      by_country: country_rows,
      by_department: department_rows,
      distribution: distribution_rows
    }
  end

  private

  def org_stats
    relation = salaries_with_rates.unscope(:select)
    total_amount, average_amount = relation.pick(
      Arel.sql(SUM_CONVERTED_SQL),
      Arel.sql(AVG_CONVERTED_SQL)
    )
    [ total_amount, average_amount, median_amount_for(relation) ]
  end

  def median_amount_for(relation)
    amounts_sql = relation.select(Arel.sql("#{CONVERTED_AMOUNT_SQL} AS converted_amount")).to_sql
    median_sql = <<~SQL.squish
      SELECT AVG(converted_amount)
      FROM (
        SELECT converted_amount,
               ROW_NUMBER() OVER (ORDER BY converted_amount) AS row_num,
               COUNT(*) OVER () AS total_count
        FROM (#{amounts_sql}) AS converted_amounts
      )
      WHERE row_num IN ((total_count + 1) / 2, (total_count + 2) / 2)
    SQL

    SalaryRecord.connection.select_value(median_sql)
  end

  def country_rows
    grouped_totals("#{SALARY}.country").map do |row|
      money_row(
        country: row.country,
        headcount: row.employee_count,
        total: row.total_amount,
        average: row.average_amount
      )
    end
  end

  def department_rows
    grouped_totals("#{SALARY}.department").map do |row|
      money_row(
        department: row.department,
        headcount: row.employee_count,
        total: row.total_amount,
        average: row.average_amount
      )
    end
  end

  def distribution_rows
    salaries_with_rates
      .unscope(:select)
      .group(Arel.sql(AMOUNT_BUCKET_SQL))
      .order(Arel.sql(AMOUNT_BUCKET_SQL))
      .select(
        "#{AMOUNT_BUCKET_SQL} AS bucket",
        "COUNT(*) AS employee_count"
      )
      .map do |row|
        { bucket: row.bucket, headcount: row.employee_count.to_i }
      end
  end

  def grouped_totals(*columns)
    salaries_with_rates
      .unscope(:select)
      .group(*columns)
      .order(*columns)
      .select(
        *columns,
        "COUNT(*) AS employee_count",
        "#{SUM_CONVERTED_SQL} AS total_amount",
        "#{AVG_CONVERTED_SQL} AS average_amount"
      )
  end

  def salaries_with_rates
    @salaries_with_rates ||= @current_salaries.joins(
      Employee.sanitize_sql_array([ EXCHANGE_RATE_JOIN_SQL, @base_currency ])
    )
  end

  def money_row(headcount:, total:, average:, **identity)
    identity.merge(
      headcount: headcount.to_i,
      total: format_money(total),
      average: format_money(average)
    )
  end

  def format_money(value)
    return "0.00" if value.nil?

    format("%.2f", BigDecimal(value.to_s).round(2))
  end
end
