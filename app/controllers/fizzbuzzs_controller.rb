class FizzbuzzsController < ApplicationController
  def show
    @calculator = Fizzbuzz.new
  end

  def create
    puts calculate_params
    @calculator = Fizzbuzz.new(calculate_params)

    @numbers = @calculator.calculate
    render 'fizzbuzzs/show'
  end

  def calculate_params
    params.require(:fizzbuzz).permit(:count)
  end
end