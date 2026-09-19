class ExchangeRate < ApplicationRecord
  validates :base_currency, presence: true, length: { is: 3 }
  validates :quote_currency, presence: true, length: { is: 3 }
  validates :rate, presence: true, numericality: { greater_than: 0 }
  validates :fetched_at, presence: true
end
