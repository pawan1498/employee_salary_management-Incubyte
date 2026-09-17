class Api::SalaryRecordsController < ApplicationController
  def create
    employee = Employee.find(params[:employee_id])
    salary_record = employee.salary_records.new(salary_record_params)

    if salary_record.save
      head :created
    else
      render json: { errors: salary_record.errors.full_messages },
             status: :unprocessable_content
    end
  end

  private

  def salary_record_params
    params.require(:salary_record).permit(:amount, :currency, :effective_date)
  end
end
