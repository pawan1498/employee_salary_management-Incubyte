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

ActiveRecord::Schema[8.1].define(version: 2026_09_17_161411) do
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
end
