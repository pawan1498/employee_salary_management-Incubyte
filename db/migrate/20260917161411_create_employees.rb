class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.string :employee_number, null: false
      t.string :name, null: false
      t.string :country, null: false
      t.string :department, null: false
      t.string :role, null: false

      t.timestamps
    end

    add_index :employees, :employee_number, unique: true
    add_index :employees, :country
    add_index :employees, :department
  end
end
