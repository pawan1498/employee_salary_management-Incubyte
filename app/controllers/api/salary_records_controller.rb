class Api::SalaryRecordsController < ApplicationController
  def create
    employee = Employee.find(params[:employee_id])
    employee.salary_records.create!(salary_record_params)
    head :created
  end

  private

  def salary_record_params
    params.require(:salary_record).permit(:amount, :currency, :effective_date)
  end
end
