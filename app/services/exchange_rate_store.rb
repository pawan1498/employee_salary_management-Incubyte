class ExchangeRateStore
  CACHE_TTL = 24.hours

  def initialize(base_currency)
    @base_currency = base_currency.to_s.upcase
  end

  def refresh_if_stale!
    return cached_snapshot(stale: false) if fresh?

    ExchangeRateFetcher.new(@base_currency).call
  rescue ExchangeRateFetcher::UnavailableError
    raise if cached_rates.empty?

    cached_snapshot(stale: true)
  end

  private

  def fresh?
    latest_fetch = ExchangeRate.where(base_currency: @base_currency).maximum(:fetched_at)
    latest_fetch.present? && latest_fetch >= CACHE_TTL.ago
  end

  def cached_rates
    ExchangeRate.where(base_currency: @base_currency).index_by(&:quote_currency)
  end

  def cached_snapshot(stale:)
    rates = cached_rates
    fetched_at = rates.values.map(&:fetched_at).max

    {
      base_currency: @base_currency,
      rates_as_of: fetched_at&.to_date,
      stale: stale,
      rates: rates.transform_values(&:rate)
    }
  end
end
