module ExchangeRateHelpers
  def frankfurter_url
    quotes = CurrencyCatalog.frankfurter_hub_quotes.join(",")
    uri = URI(CurrencyCatalog::FRANKFURTER_URL)
    uri.query = URI.encode_www_form(from: CurrencyCatalog.hub, to: quotes)
    uri.to_s
  end

  DEFAULT_HUB_RATES = {
    "USD" => BigDecimal("1.0"),
    "GBP" => BigDecimal("0.79"),
    "EUR" => BigDecimal("0.92"),
    "INR" => BigDecimal("83.5"),
    "CAD" => BigDecimal("1.35"),
    "JPY" => BigDecimal("149.25")
  }.freeze

  def seed_exchange_rates(rates: DEFAULT_HUB_RATES, fetched_at: Time.current)
    rates.each do |quote_currency, rate|
      ExchangeRate.create!(
        base_currency: CurrencyCatalog.hub,
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
