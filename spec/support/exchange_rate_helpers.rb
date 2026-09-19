module ExchangeRateHelpers
  def frankfurter_url(base_currency)
    quotes = CurrencyCatalog.frankfurter_quote_currencies(base_currency).join(",")
    uri = URI(CurrencyCatalog::FRANKFURTER_URL)
    uri.query = URI.encode_www_form(from: base_currency, to: quotes)
    uri.to_s
  end

  DEFAULT_RATES = {
    "USD" => BigDecimal("1.0"),
    "GBP" => BigDecimal("0.79"),
    "EUR" => BigDecimal("0.92"),
    "INR" => BigDecimal("83.5"),
    "CAD" => BigDecimal("1.35")
  }.freeze

  def seed_exchange_rates(base_currency: "USD", rates: DEFAULT_RATES, fetched_at: Time.current)
    rates.each do |quote_currency, rate|
      ExchangeRate.create!(
        base_currency: base_currency,
        quote_currency: quote_currency,
        rate: rate,
        fetched_at: fetched_at
      )
    end
  end
end

RSpec.configure do |config|
  config.include ExchangeRateHelpers
end
