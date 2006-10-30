# This files contains testcases for the Turing::Machine class

require 'test/unit'
require 'turing/machine'

class MachineTests < Test::Unit::TestCase #:nodoc:

  def test_input_tape
    machine = Turing::Machine.new('machines/add.tur')
    machine.setup('01010')
    assert_equal(['0', '1', '0', '1', '0'], machine.tape)
  end

  def test_three_ones_to_zeros
    machine = Turing::Machine.new('machines/3ones2zeroes.tur')
    machine.setup('1110111')
    machine.process
    assert_equal(['0', '0', '0', '0', '0', '0', '0' ], machine.tape)
    assert(machine.halted)
  end

  def test_empty
    machine = Turing::Machine.new("machines/empty.tur")
    machine.setup('0')
    assert_equal(1, machine.machines.size)
    assert(machine.halted)
  end

  def test_step
    machine = Turing::Machine.new('machines/swap.tur')
    machine.setup('0101')
    machine.process
    assert_equal(['1','0','1','0'], machine.tape)
    machine.setup('1010')
    machine.process
    assert_equal(['0','1','0','1'], machine.tape)
  end

  def test_add
    machine = Turing::Machine.new('machines/add.tur')
    machine.setup('01010')
    machine.process
    assert_equal(['0','1','1','0','_'], machine.tape)
  end

  def test_next
    machine = Turing::Machine.new('machines/swap.tur')
    machine.setup('01010')
    machine.step
    assert(!machine.halted)
  end
end
