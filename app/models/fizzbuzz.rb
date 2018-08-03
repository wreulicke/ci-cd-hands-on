class Fizzbuzz include ActiveModel::Model
  attr_accessor :count

  validates :count, presence: true, numericality: { only_integer: true }

  def calculate
    (1..(count.to_i)).map do |i|
      if i % 10 == 0
        "FizzBuzz"
      elsif i % 5 == 0
        "Buzz"
      elsif i % 3 == 0
        "Fizz"
      else
        i.to_s
      end
    end
  end
end