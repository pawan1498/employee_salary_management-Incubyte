class Api::EmployeesController < ApplicationController
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  def index
    scope = Employee.order(:name, :id)
                    .search(params[:q])
                    .in_country(params[:country])
                    .in_department(params[:department])
    employees = scope.includes(:salary_records)
                     .offset((page - 1) * per_page)
                     .limit(per_page)

    render json: {
      data: employees.map { |employee| employee_payload(employee) },
      meta: { page: page, per_page: per_page, total: scope.count }
    }
  end

  def show
    employee = Employee.includes(:salary_records).find(params[:id])
    render json: { data: employee_payload(employee, include_history: true) }
  end

  private

  def page
    [ params.fetch(:page, 1).to_i, 1 ].max
  end

  def per_page
    value = params.fetch(:per_page, DEFAULT_PER_PAGE).to_i
    value = DEFAULT_PER_PAGE if value < 1
    [ value, MAX_PER_PAGE ].min
  end

  def employee_payload(employee, include_history: false)
    payload = employee.as_json(only: %i[id employee_number name country department role])
    payload["current_salary"] = salary_payload(employee.current_salary_record)
    payload["salary_history"] = employee.salary_history.map { |record| salary_payload(record) } if include_history
    payload
  end

  def salary_payload(record)
    return if record.nil?

    record.as_json(only: %i[id amount currency effective_date])
  end
end
