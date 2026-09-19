class SalaryRecord < ApplicationRecord
  belongs_to :employee

  validates :amount, numericality: { greater_than: 0 }
  validates :currency, presence: true, inclusion: {
    in: ->(_) { CurrencyCatalog.currencies },
    message: "is not a supported currency"
  }
  validates :effective_date, presence: true

  scope :newest_first, -> { order(effective_date: :desc, id: :desc) }
end
