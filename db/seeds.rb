# Creates 10,000 employees with current salaries (and some history).
# Safe to re-run: it only inserts until the directory reaches 10,000.
EmployeeSeeder.new.call
puts "Seeded #{Employee.count} employees and #{SalaryRecord.count} salary records."
