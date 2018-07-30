require 'rails_helper'

describe Fizzbuzz do
  subject (:fizzbuzz) { Fizzbuzz.new(count: 99).calculate }

  it '3の倍数かつ5の倍数でないときはFizz' do
    expect(fizzbuzz[6 - 1]).to eq "Fizz"
  end

  it '3の倍数でないかつ5の倍数であるときはBuzz' do
    expect(fizzbuzz[10 - 1]).to eq "Buzz"
  end

  it '15の倍数のときはFizzBuzz' do
    expect(fizzbuzz[30 - 1]).to eq "FizzBuzz"
  end

  it 'それ以外のときはその数字' do
    expect(fizzbuzz[23 - 1]).to eq "23"
  end
end