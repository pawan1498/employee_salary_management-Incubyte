class EmployeeSeeder
  TARGET = 10_000
  BATCH_SIZE = 500

  LOCATIONS = [
    { country: "United States", currency: "USD", min: 55_000, max: 175_000 },
    { country: "United Kingdom", currency: "GBP", min: 35_000, max: 120_000 },
    { country: "India", currency: "INR", min: 600_000, max: 2_500_000 },
    { country: "Germany", currency: "EUR", min: 40_000, max: 130_000 },
    { country: "Canada", currency: "CAD", min: 50_000, max: 160_000 }
  ].freeze

  DEPARTMENTS = {
    "Engineering" => [ "Software Engineer", "Backend Engineer", "Engineering Manager" ].freeze,
    "People" => [ "HR Generalist", "Recruiter" ].freeze,
    "Finance" => [ "Accountant", "Financial Analyst" ].freeze,
    "Sales" => [ "Account Executive", "Sales Manager" ].freeze,
    "Operations" => [ "Operations Specialist", "Office Manager" ].freeze
  }.freeze

  FIRST_NAMES = %w[
    Ada Alan Grace Katherine Linus Margaret Satya Priya Omar Elena
    James Sofia Liam Noah Emma Olivia Ava Ethan Mason Aria Leo
    Ananya Arjun Rohan Neha Vikram Meera Ishaan Kavya Rahul Pooja
    Hans Anna Klaus Sophie Pierre Marie Luca Giulia Carlos Lucia
    Mei Yuki Chen Raj Anika Dev Maya Arun Sana Yusuf Fatima
  ].freeze

  LAST_NAMES = %w[
    Lovelace Turing Hopper Johnson Torvalds Hamilton Nadella Sharma Khan Becker
    Smith Williams Brown Jones Garcia Miller Davis Rodriguez Wilson
    Anderson Thomas Taylor Moore Jackson Martin Lee Thompson White
    Patel Singh Gupta Reddy Iyer Nair Menon Das Banerjee Joshi
    Mueller Schmidt Weber Fischer Dubois Bernard Rossi Costa Nguyen
    Kim Park Tan Ali Hassan Ibrahim Fernandez Lopez Clark Lewis
  ].freeze

  def initialize(count: TARGET, random: Random.new)
    @count = count
    @random = random
  end

  def call
    created = Employee.count
    return created if created >= @count

    ((created + 1)..@count).each_slice(BATCH_SIZE) { |indexes| insert_batch(indexes) }
    @count
  end

  private

  def insert_batch(indexes)
    now = Time.current
    employee_rows = indexes.map { |index| employee_row(index, now) }
    Employee.insert_all(employee_rows)

    ids_by_number = Employee.where(employee_number: employee_rows.map { |row| row[:employee_number] })
                            .pluck(:employee_number, :id)
                            .to_h

    salary_rows = indexes.flat_map { |index| salary_rows_for(index, ids_by_number, now) }
    SalaryRecord.insert_all(salary_rows)
  end

  def employee_row(index, now)
    location = LOCATIONS[index % LOCATIONS.size]
    department = DEPARTMENTS.keys[index % DEPARTMENTS.size]
    role = DEPARTMENTS.fetch(department).sample(random: @random)

    {
      employee_number: format("E-%05d", index),
      name: random_name(index),
      country: location.fetch(:country),
      department: department,
      role: role,
      created_at: now,
      updated_at: now
    }
  end

  def salary_rows_for(index, ids_by_number, now)
    location = LOCATIONS[index % LOCATIONS.size]
    employee_id = ids_by_number.fetch(format("E-%05d", index))
    current_amount = amount_for(location)

    rows = [ salary_row(employee_id, current_amount, location.fetch(:currency), Date.new(2026, 1, 1), now) ]
    if (index % 3).zero?
      previous_amount = (current_amount * 0.85).round(2)
      rows.unshift(salary_row(employee_id, previous_amount, location.fetch(:currency), Date.new(2024, 1, 1), now))
    end
    rows
  end

  def salary_row(employee_id, amount, currency, effective_date, now)
    {
      employee_id: employee_id,
      amount: amount,
      currency: currency,
      effective_date: effective_date,
      created_at: now,
      updated_at: now
    }
  end

  def amount_for(location)
    @random.rand(location.fetch(:min)..location.fetch(:max)).round(-2)
  end

  def random_name(index)
    first = FIRST_NAMES[(index + @random.rand(FIRST_NAMES.size)) % FIRST_NAMES.size]
    last = LAST_NAMES[((index * 17) + @random.rand(LAST_NAMES.size)) % LAST_NAMES.size]
    "#{first} #{last}"
  end
end
