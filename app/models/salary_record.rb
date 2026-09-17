class SalaryRecord < ApplicationRecord
  belongs_to :employee

  validates :amount, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :effective_date, presence: true
end
