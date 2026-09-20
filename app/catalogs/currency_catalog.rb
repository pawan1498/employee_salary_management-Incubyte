# Reference data (not an ActiveRecord model). Single source of truth for currency codes and FX config.
#
# - CURRENCIES: Frankfurter-supported ISO codes — used for salary records, insights
#   base_currency, exchange rates, and every UI currency dropdown
# - COUNTRY_CURRENCY: each seed country maps to one salary currency (must be in CURRENCIES)
# - HUB: Frankfurter always fetches from this currency; other bases are derived
# - DEFAULT: base_currency when the client sends none
class CurrencyCatalog
  DEFAULT = "USD"
  HUB = "USD"
  FRANKFURTER_URL = "https://api.frankfurter.dev/v1/latest"

  COUNTRY_CURRENCY = {
    "United States" => "USD",
    "United Kingdom" => "GBP",
    "India" => "INR",
    "Germany" => "EUR",
    "Canada" => "CAD"
  }.freeze

  # Must stay aligned with https://api.frankfurter.dev/v1/currencies
  CURRENCIES = %w[
    AUD BRL CAD CHF CNY CZK DKK EUR GBP HKD HUF IDR ILS INR ISK JPY KRW
    MXN MYR NOK NZD PHP PLN RON SEK SGD THB TRY USD ZAR
  ].freeze

  def self.default
    DEFAULT
  end

  def self.hub
    HUB
  end

  def self.currency_for(country)
    COUNTRY_CURRENCY.fetch(country)
  end

  def self.countries
    COUNTRY_CURRENCY.keys.sort
  end

  def self.currencies
    CURRENCIES.sort
  end

  def self.supported?(code)
    CURRENCIES.include?(code.to_s.upcase)
  end

  def self.frankfurter_hub_quotes
    currencies.reject { |currency| currency == HUB }.sort
  end
end
