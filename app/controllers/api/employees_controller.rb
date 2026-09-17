class Api::EmployeesController < ApplicationController
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  def index
    page = [ params.fetch(:page, 1).to_i, 1 ].max
    per_page = params.fetch(:per_page, DEFAULT_PER_PAGE).to_i
    per_page = DEFAULT_PER_PAGE if per_page < 1
    per_page = [ per_page, MAX_PER_PAGE ].min

    scope = Employee.order(:name, :id)
                    .search(params[:q])
                    .in_country(params[:country])
                    .in_department(params[:department])
    employees = scope.offset((page - 1) * per_page).limit(per_page)

    render json: {
      data: employees.map { |employee| employee_payload(employee) },
      meta: { page: page, per_page: per_page, total: scope.count }
    }
  end

  def show
    employee = Employee.find(params[:id])
    render json: { data: employee_payload(employee) }
  end

  private

  def employee_payload(employee)
    employee.as_json(only: %i[id employee_number name country department role])
  end
end
