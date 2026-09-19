require "net/http"
require "json"

class ExchangeRateFetcher
  class UnavailableError < StandardError; end

  def initialize(base_currency)
    @base_currency = base_currency.to_s.upcase
  end

  def call
    response = fetch_rates
    rates_as_of = Date.parse(response.fetch("date"))
    fetched_at = Time.current

    upsert_rate(@base_currency, @base_currency, BigDecimal("1"), fetched_at)

    response.fetch("rates").each do |quote_currency, rate|
      upsert_rate(@base_currency, quote_currency, BigDecimal(rate.to_s), fetched_at)
    end

    {
      base_currency: @base_currency,
      rates_as_of: rates_as_of,
      stale: false,
      rates: rates_hash
    }
  end

  private

  def fetch_rates
    uri = URI(CurrencyCatalog::FRANKFURTER_URL)
    uri.query = URI.encode_www_form(
      from: @base_currency,
      to: CurrencyCatalog.frankfurter_quote_currencies(@base_currency).join(",")
    )

    response = Net::HTTP.get_response(uri)
    raise UnavailableError unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, SocketError
    raise UnavailableError
  end

  def upsert_rate(base_currency, quote_currency, rate, fetched_at)
    record = ExchangeRate.find_or_initialize_by(
      base_currency: base_currency,
      quote_currency: quote_currency.to_s.upcase
    )
    record.update!(rate: rate, fetched_at: fetched_at)
  end

  def rates_hash
    ExchangeRate.where(base_currency: @base_currency).each_with_object({}) do |record, rates|
      rates[record.quote_currency] = record.rate
    end
  end
end
