# This files contains testcases for the Turing::Machine class
require 'test/unit'
require 'turing/machine'

class MachineTests < Test::Unit::TestCase #:nodoc:
  def test_input_tape
    machine = Turing::Machine.from_file('machines/add.tur')
    machine.setup('01010')
    assert_equal(['#', '0', '1', '0', '1', '0'], machine.tape)
  end

  def test_three_ones_to_zeros
    machine = Turing::Machine.from_file('machines/3ones2zeroes.tur')
    machine.setup('1110111')
    machine.process
    assert_equal(['#', '0', '0', '0', '0', '0', '0', '0' ], machine.tape)
    assert(machine.halted)
  end

  def test_empty
    machine = Turing::Machine.from_file("machines/empty.tur")
    machine.setup('0')
    assert_equal(1, machine.machines.size)
    assert(machine.halted)
  end

  def test_step
    machine = Turing::Machine.from_file('machines/swap.tur')
    machine.setup('0101')
    machine.process
    assert_equal(['#', '1','0','1','0'], machine.tape)
    machine.setup('1010')
    machine.process
    assert_equal(['#', '0','1','0','1'], machine.tape)
  end

  def test_add
    machine = Turing::Machine.from_file('machines/add.tur')
    machine.setup('01010')
    machine.process
    assert_equal(['#', '0','1','1','0','_'], machine.tape)
  end

  def test_next
    machine = Turing::Machine.from_file('machines/swap.tur')
    machine.setup('01010')
    machine.step
    assert(!machine.halted)
  end
  
  def test_both_sides
    machine = Turing::Machine.from_file('machines/all_the_way_left.tur')
    machine.setup('')
    machine.step(5)
    assert_equal(['_', '0', '0', '0', '0', '0'], machine.tape)
  end

  def test_alpha
    machine = Turing::Machine.from_file('machines/swap_alpha.tur')
    machine.setup('abab')
    machine.process
    assert_equal(['#', 'b','a','b','a'], machine.tape)
  end

  def test_alpha2
    machine = Turing::Machine.from_file('machines/swap_alpha2.tur')
    machine.setup('abab')
    machine.process
    assert_equal(['#', 'b','a','b','a'], machine.tape)
  end

  def test_wies_palin
    Turing::Machine.default_kind = "Wiesbaden"
    machine = Turing::Machine.from_file('machines/wies_palin.tur')
    machine.setup('_AAABBAAA')
    machine.process
    assert_equal(['#', '_','Y','E', 'S', '_', '_', '_', '_', '_', '_'], machine.tape)
  end
end
