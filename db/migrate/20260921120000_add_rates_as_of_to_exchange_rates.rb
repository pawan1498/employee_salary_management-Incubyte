class AddRatesAsOfToExchangeRates < ActiveRecord::Migration[8.1]
  def change
    add_column :exchange_rates, :rates_as_of, :date

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE exchange_rates
          SET rates_as_of = DATE(fetched_at)
          WHERE rates_as_of IS NULL
        SQL
      end
    end

    change_column_null :exchange_rates, :rates_as_of, false
  end
end
