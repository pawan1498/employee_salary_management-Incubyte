class Employee < ApplicationRecord
  validates :employee_number, :name, :country, :department, :role, presence: true
  validates :employee_number, uniqueness: true
end
