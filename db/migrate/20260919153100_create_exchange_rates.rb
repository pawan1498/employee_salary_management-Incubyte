class CreateExchangeRates < ActiveRecord::Migration[8.1]
  def change
    create_table :exchange_rates do |t|
      t.string :base_currency, null: false, limit: 3
      t.string :quote_currency, null: false, limit: 3
      t.decimal :rate, null: false, precision: 18, scale: 8
      t.datetime :fetched_at, null: false

      t.timestamps
    end

    add_index :exchange_rates, [ :base_currency, :quote_currency ], unique: true
  end
end
