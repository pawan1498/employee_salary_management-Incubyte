class Api::FiltersController < ApplicationController
  def show
    render json: { data: ::EmployeeCatalog.filter_options }
  end
end
