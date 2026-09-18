class Api::InsightsController < ApplicationController
  def show
    employees = Employee.in_country(params[:country]).in_department(params[:department])
    render json: { data: CompensationInsights.call(employees) }
  end
end
