require "rails_helper"

RSpec.describe SalaryRecord, type: :model do
  let(:employee) do
    Employee.create!(
      employee_number: "E-1001",
      name: "Pawan Sharma",
      country: "India",
      department: "Engineering",
      role: "Backend Engineer"
    )
  end

  let(:valid_attributes) do
    {
      employee: employee,
      amount: 100_000,
      currency: "INR",
      effective_date: Date.new(2026, 1, 15)
    }
  end

  it "is valid with amount, currency, and effective date" do
    expect(SalaryRecord.new(valid_attributes)).to be_valid
  end

  context "when amount is zero" do
    it "is invalid" do
      record = SalaryRecord.new(valid_attributes.merge(amount: 0))

      expect(record).not_to be_valid
      expect(record.errors[:amount]).to be_present
    end
  end

  context "when currency is missing" do
    it "is invalid" do
      record = SalaryRecord.new(valid_attributes.merge(currency: nil))

      expect(record).not_to be_valid
      expect(record.errors[:currency]).to be_present
    end
  end

  context "when effective date is missing" do
    it "is invalid" do
      record = SalaryRecord.new(valid_attributes.merge(effective_date: nil))

      expect(record).not_to be_valid
      expect(record.errors[:effective_date]).to be_present
    end
  end
end
