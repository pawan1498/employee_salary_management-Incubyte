class ExchangeRateStore
  CACHE_TTL = 24.hours

  def initialize(base_currency)
    @base_currency = base_currency.to_s.upcase
  end

  def refresh_if_stale!
    ensure_hub_fresh!
    derived_snapshot(stale: false)
  rescue ExchangeRateFetcher::UnavailableError
    raise if hub_rate_rows.empty?

    derived_snapshot(stale: true)
  end

  private

  def ensure_hub_fresh!
    return if hub_fresh?

    ExchangeRateFetcher.new.call
  end

  def hub_fresh?
    latest_fetch = ExchangeRate.where(base_currency: CurrencyCatalog.hub).maximum(:fetched_at)
    latest_fetch.present? && latest_fetch >= CACHE_TTL.ago
  end

  def hub_rate_rows
    ExchangeRate.where(base_currency: CurrencyCatalog.hub).index_by(&:quote_currency)
  end

  def derived_snapshot(stale:)
    hub_rates = hub_rate_rows
    hub_values = hub_rates.transform_values(&:rate)
    hub_values[CurrencyCatalog.hub] = BigDecimal("1")

    base_hub_rate = hub_values.fetch(@base_currency) do
      raise ExchangeRateFetcher::UnavailableError
    end

    quote_currencies = hub_values.keys | [ @base_currency ]
    rates = quote_currencies.index_with do |quote_currency|
      quote_hub_rate = hub_values.fetch(quote_currency)
      quote_hub_rate / base_hub_rate
    end

    fetched_at = hub_rates.values.map(&:fetched_at).max
    rates_as_of = hub_rates.values.map(&:rates_as_of).max
    materialize_derived_rates!(rates, fetched_at:, rates_as_of:) unless @base_currency == CurrencyCatalog.hub

    {
      base_currency: @base_currency,
      rates_as_of: rates_as_of,
      stale: stale,
      rates: rates
    }
  end

  def materialize_derived_rates!(rates, fetched_at:, rates_as_of:)
    rates.each do |quote_currency, rate|
      record = ExchangeRate.find_or_initialize_by(
        base_currency: @base_currency,
        quote_currency: quote_currency
      )
      record.update!(rate: rate, fetched_at: fetched_at, rates_as_of: rates_as_of)
    end
  end
end
