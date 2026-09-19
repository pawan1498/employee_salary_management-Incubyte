class Api::InsightsController < ApplicationController
  def show
    base_currency = requested_base_currency
    unless CurrencyCatalog.supported?(base_currency)
      return render json: { errors: [ "Base currency is not supported" ] },
                    status: :unprocessable_content
    end

    rate_snapshot = ExchangeRateStore.new(base_currency).refresh_if_stale!
    employees = Employee.in_country(params[:country]).in_department(params[:department])

    render json: {
      data: CompensationInsights.call(
        employees,
        base_currency: rate_snapshot.fetch(:base_currency),
        rates_as_of: rate_snapshot.fetch(:rates_as_of)
      )
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
