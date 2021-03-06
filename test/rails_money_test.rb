require File.dirname(__FILE__) + '/test_helper'

class Thing < ActiveRecord::Base
end

class ValidatedThing < ActiveRecord::Base
  validates_numericality_of :required, :greater_than => 0.50,
    :less_than_or_equal_to => 20 # implies allow_nil => false
  validates_numericality_of :optional, :greater_than => 0.50,
    :less_than_or_equal_to => 20, :allow_nil => true
end

def thing
  Thing.new(:name => "Thing One",:price_in_cents=> 125)
end

def validated_thing
  ValidatedThing.new(:name => "Thing Two")
end

class RailsMoneyTest < Test::Unit::TestCase
  
  def test_should_return_price_as_money_object
    price = thing.price
    assert_kind_of Money, price
    assert_equal "$1.25", thing.price.to_s
  end
  def test_negative_method
    price = thing.price
    assert_equal("($1.25)", (-price).to_s)
  end
  def test_should_set_price_from_money_object
    thing1 = thing 
    thing1.price = Money.new(1095)
    assert_equal 109500, thing1.price_in_cents
    assert_equal "$1,095.00", thing1.price.to_s
  end

  def test_should_set_price_from_fixnum
    thing1 = thing
    thing1.price = 1095
    assert_equal 109500, thing1.price_in_cents
  end

  def test_should_set_price_from_float
    thing1 = thing
    thing1.price = 10.95
    assert_equal 1095, thing1.price_in_cents
  end
  
  def test_should_set_price_from_string
    thing1 = thing
    thing1.price = "$10.95"
    assert_equal 1095, thing1.price_in_cents
    thing1.price = "10"
    assert_equal 1000, thing1.price_in_cents
  end

  def test_should_validate_successfully
    thing1 = validated_thing
    thing1.required = 1.25
    assert thing1.valid?, "#{thing1.inspect} - #{thing1.errors.full_messages.to_sentence}"
  end

  def test_should_fail_to_validate_successfully
    thing1 = validated_thing
    [0.01, 100, -100, "orange"].each do |x|
      thing1.required = x
      assert !thing1.valid?
      assert thing1.errors.invalid?(:required)
    end
    thing1.required = 10
    assert thing1.valid?, "#{thing1.inspect} - #{thing1.errors.full_messages.to_sentence}"
    assert !thing1.errors.invalid?(:optional)
  end
end

class MoneyTest < Test::Unit::TestCase
   
  def test_should_create_money_object
    assert cash_money = Money.new(1290)
    assert_equal 129000, cash_money.cents
    assert_equal 1290, cash_money.dollars
    assert_equal "$1,290.00", cash_money.to_s
    assert_equal false, cash_money.free?
    assert_equal 0, Money.new(nil).cents
  end

  def test_should_create_money_object_from_float_with_proper_rounding
    money =  Money.new(12.196)
    assert_equal 1220, money.cents
    assert_instance_of Fixnum, money.cents 
  end

  def test_should_create_money_object_from_another_money_object
    money =  Money.new(12.196)
    assert_equal 1220, money.cents
    new_money = Money.new(money)
    assert_equal 1220, new_money.cents
  end
  
  def test_should_raise_exception_if_invalid_type_passed_to_initialize
    assert_raise(TypeError) { Money.new([]) }
  end

  def test_should_return_correct_value_on_to_s_if_cents_is_zero
    cash_money = Money.new(0)
    assert_equal '$0.00', cash_money.to_s
    assert_equal 'free', cash_money.to_s(:zero_string => 'free')
    assert_equal true, cash_money.free?
    assert_equal true, cash_money.zero?
    
  end

  def test_should_be_comparable
    assert Money.include?(Comparable)
    assert Money.new(0) == Money.new(0)
  end

  def test_should_add_money
    assert_equal Money.new(20.95), Money.new(10) + Money.new(10.95)
    assert_equal Money.new(2000), Money.new(1000) + 1000
    assert_equal Money.new(20.06), Money.new(10.00) + 10.056
  end

  def test_should_subtract_money
    assert_equal Money.new(500), Money.new(1000) - Money.new(500)
    assert_equal Money.new(500),  Money.new(1000) - 500
    assert_equal Money.new(4.60),  Money.new(10) - 5.40
  end

  def test_should_multiply_money
    assert_equal Money.new(500), Money.new(100) * 5
    assert_equal Money.new(9.99), Money.new(3.33) * 3
    assert_equal Money.new(11.99), Money.new(3.33) * 3.6 # 1198.9
  end

  def test_should_divide_money_and_return_array_of_monies
    money_array = [Money.new(3.34), Money.new(3.33), Money.new(3.33)]
    assert_equal money_array, Money.new(10.00) / 3
    assert_equal [Money.new(2.00), Money.new(2.00)], Money.new(4.00) / 2
    assert_raises(ArgumentError) { Money.new(4.00) / 2.2 }
  end

  def test_should_implement_to_money
    assert_equal Money.new(10), Money.new(10).to_money
    assert_equal Money.new(100.00), 100.00.to_money
    assert_equal Money.new(100.96), 100.956.to_money
  end
  
  def test_should_create_from_cents
    assert_equal Money.new(1.50), Money.create_from_cents(150)
  end

  def test_should_format_correctly
    assert_equal "$12.40", Money.new(12.40).to_s
  end
end
