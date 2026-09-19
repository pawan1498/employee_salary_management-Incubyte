class Api::ExchangeRatesController < ApplicationController
  def show
    base_currency = requested_base_currency
    unless CurrencyCatalog.supported?(base_currency)
      return render json: { errors: [ "Base currency is not supported" ] },
                    status: :unprocessable_content
    end

    snapshot = ExchangeRateStore.new(base_currency).refresh_if_stale!

    render json: {
      data: {
        base_currency: snapshot.fetch(:base_currency),
        rates_as_of: snapshot.fetch(:rates_as_of)&.iso8601,
        rates: snapshot.fetch(:rates).transform_values { |rate| format("%.6f", rate) }
      }
    }
  rescue ExchangeRateFetcher::UnavailableError
    render json: { errors: [ "Exchange rates are temporarily unavailable" ] },
           status: :service_unavailable
  end

  private

  def requested_base_currency
    params.fetch(:base_currency, CurrencyCatalog.default).to_s.upcase
  end
end
