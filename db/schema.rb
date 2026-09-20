# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_21_120000) do
  create_table "employees", force: :cascade do |t|
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.string "department", null: false
    t.string "employee_number", null: false
    t.string "name", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["country"], name: "index_employees_on_country"
    t.index ["department"], name: "index_employees_on_department"
    t.index ["employee_number"], name: "index_employees_on_employee_number", unique: true
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.string "base_currency", limit: 3, null: false
    t.datetime "created_at", null: false
    t.datetime "fetched_at", null: false
    t.string "quote_currency", limit: 3, null: false
    t.decimal "rate", precision: 18, scale: 8, null: false
    t.date "rates_as_of", null: false
    t.datetime "updated_at", null: false
    t.index ["base_currency", "quote_currency"], name: "index_exchange_rates_on_base_currency_and_quote_currency", unique: true
  end

  create_table "salary_records", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, null: false
    t.date "effective_date", null: false
    t.integer "employee_id", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "effective_date"], name: "index_salary_records_on_employee_id_and_effective_date"
    t.index ["employee_id"], name: "index_salary_records_on_employee_id"
  end

  add_foreign_key "salary_records", "employees"
end
