# Single source of truth for all currency codes and FX configuration in this app.
#
# - COUNTRY_CURRENCY: each seed country maps to one salary currency
# - SALARY: derived from COUNTRY_CURRENCY (Frankfurter "to" list for FX)
# - REPORTING: currencies HR may pick for insights (Frankfurter "from" list)
# - DEFAULT: insights base_currency when the client sends none
class CurrencyCatalog
  DEFAULT = "USD"
  FRANKFURTER_URL = "https://api.frankfurter.dev/v1/latest"

  COUNTRY_CURRENCY = {
    "United States" => "USD",
    "United Kingdom" => "GBP",
    "India" => "INR",
    "Germany" => "EUR",
    "Canada" => "CAD"
  }.freeze

  SALARY = COUNTRY_CURRENCY.values.uniq.sort.freeze

  REPORTING = %w[
    AUD BGN BRL CAD CHF CNY CZK DKK EUR GBP HKD HUF IDR ILS INR ISK JPY KRW
    MXN MYR NOK NZD PHP PLN RON SEK SGD THB TRY USD ZAR
  ].freeze

  def self.default
    DEFAULT
  end

  def self.currency_for(country)
    COUNTRY_CURRENCY.fetch(country)
  end

  def self.countries
    COUNTRY_CURRENCY.keys.sort
  end

  def self.salary_currencies
    SALARY
  end

  def self.reporting_currencies
    REPORTING.sort
  end

  def self.reporting?(code)
    REPORTING.include?(code.to_s.upcase)
  end

  def self.salary?(code)
    SALARY.include?(code.to_s.upcase)
  end

  def self.frankfurter_quote_currencies(base_currency)
    salary_currencies.reject { |currency| currency == base_currency.to_s.upcase }
  end
end
